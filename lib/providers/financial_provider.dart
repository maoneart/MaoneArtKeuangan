import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/saving_model.dart';
import '../models/financial_summary.dart';
import '../services/database_helper.dart';
import '../services/gemini_service.dart';
import '../services/phpmyadmin_service.dart';

// Database Instance Provider
final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// Filter Periode Bulan (Format: 'YYYY-MM', default: bulan sekarang)
final selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

// Filter Tipe Transaksi ('semua', 'pemasukan', 'pengeluaran')
final transactionTypeFilterProvider = StateProvider<String>((ref) => 'semua');

// Search Query Transaksi
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

// 1. Categories Provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getCategories();
});

// 2. Financial Summary Provider
final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) async {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  return await db.getFinancialSummary(month: month);
});

// 3. Transactions Provider
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final type = ref.watch(transactionTypeFilterProvider);
  final query = ref.watch(transactionSearchQueryProvider);

  return await db.getTransactions(
    month: month,
    type: type,
    searchQuery: query,
  );
});

// 4. Debts Provider
final debtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getDebts();
});

// 5. Savings Provider
final savingsProvider = FutureProvider<List<SavingModel>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getSavings();
});

// Notifier untuk memicu refresh data global
class FinancialController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  FinancialController(this.ref) : super(const AsyncValue.data(null));

  Future<void> addTransaction(TransactionModel tx) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      await db.insertTransaction(tx);
      _refreshAll();
      _autoSyncToPhpMyAdmin();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> syncWithPhpMyAdmin() async {
    final db = ref.read(databaseProvider);
    final result = await PhpMyAdminService.syncFull(db);
    _refreshAll();
    return result;
  }

  void _autoSyncToPhpMyAdmin() {
    try {
      final db = ref.read(databaseProvider);
      PhpMyAdminService.syncFull(db).then((_) {
        _refreshAll();
      }).catchError((_) {});
    } catch (_) {}
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.deleteTransaction(id);
      _refreshAll();
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> addDebt(DebtModel debt) async {
    try {
      final db = ref.read(databaseProvider);
      await db.insertDebt(debt);
      ref.invalidate(debtsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> payDebt(int debtId, double amount, DateTime paymentDate, {String? note}) async {
    try {
      final db = ref.read(databaseProvider);
      await db.addDebtPayment(debtId, amount, paymentDate, note: note);
      ref.invalidate(debtsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> deleteDebt(int id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.deleteDebt(id);
      ref.invalidate(debtsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> addSaving(SavingModel saving) async {
    try {
      final db = ref.read(databaseProvider);
      await db.insertSaving(saving);
      ref.invalidate(savingsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> depositSaving(int savingId, double amount, DateTime depositDate, {String? note}) async {
    try {
      final db = ref.read(databaseProvider);
      await db.addSavingDeposit(savingId, amount, depositDate, note: note);
      ref.invalidate(savingsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> addSavingDeposit(SavingDepositModel deposit) async {
    return depositSaving(deposit.savingId, deposit.amount, deposit.depositDate, note: deposit.note);
  }

  Future<void> deleteSaving(int id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.deleteSaving(id);
      ref.invalidate(savingsProvider);
      ref.invalidate(financialSummaryProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final db = ref.read(databaseProvider);
      await db.insertCategory(category);
      ref.invalidate(categoriesProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  Future<void> deleteCategory(int id) async {
    try {
      final db = ref.read(databaseProvider);
      await db.deleteCategory(id);
      ref.invalidate(categoriesProvider);
      _autoSyncToPhpMyAdmin();
    } catch (_) {}
  }

  void _refreshAll() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(financialSummaryProvider);
    ref.invalidate(debtsProvider);
    ref.invalidate(savingsProvider);
  }

  Future<void> resetAllData() async {
    try {
      final db = ref.read(databaseProvider);
      await db.resetAllTransactionsData();
      try {
        await PhpMyAdminService.resetRemoteData();
      } catch (_) {}
      _refreshAll();
    } catch (_) {}
  }
}

final financialControllerProvider = StateNotifierProvider<FinancialController, AsyncValue<void>>((ref) {
  return FinancialController(ref);
});

// Gemini API Key State Management (Real-Time Synchronized Across All Screens)
class GeminiApiKeyNotifier extends StateNotifier<String> {
  GeminiApiKeyNotifier() : super('') {
    loadKey();
  }

  Future<void> loadKey() async {
    final key = await GeminiService.getApiKey();
    state = key ?? '';
  }

  Future<void> setKey(String key) async {
    await GeminiService.saveApiKey(key);
    state = key.trim();
  }

  Future<void> removeKey() async {
    await GeminiService.removeApiKey();
    state = '';
  }
}

final geminiApiKeyProvider = StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});
