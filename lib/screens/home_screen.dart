import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/financial_summary.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/balance_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/quick_add_modal.dart';
import 'category_management_screen.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final debtsAsync = ref.watch(debtsProvider);
    final savingsAsync = ref.watch(savingsProvider);
    final currentMonth = ref.watch(selectedMonthProvider);

    // Parsing label bulan
    final parts = currentMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final periodLabel = AppDateFormatter.formatMonthYear(monthDate);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentEmerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentEmerald, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MaoneArt Keuangan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Catatan Keuangan Cerdas', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded, color: Colors.white70, size: 20),
            tooltip: 'Kelola Kategori',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialSummaryProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(debtsProvider);
          ref.invalidate(savingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Balance Card Besar
              summaryAsync.when(
                data: (summary) => BalanceCard(
                  summary: summary,
                  periodLabel: periodLabel,
                  onMonthTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: monthDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      final newMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                      ref.read(selectedMonthProvider.notifier).state = newMonth;
                    }
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Gagal memuat saldo'),
              ),
              const SizedBox(height: 16),

              // 2. Quick Action Buttons (+ Pemasukan & + Pengeluaran)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => QuickAddModal.show(context, type: 'pemasukan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentEmerald,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.black),
                      label: Text('+ Pemasukan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => QuickAddModal.show(context, type: 'pengeluaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.white),
                      label: Text('+ Pengeluaran', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Mini Overview: Tabungan & Hutang Piutang
              Row(
                children: [
                  // Box Tabungan Terkumpul
                  Expanded(
                    child: summaryAsync.when(
                      data: (summary) => GlassCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => onNavigateTab(2), // Tabungan
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.savings_rounded, color: AppTheme.accentCyan, size: 18),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Tabungan Impian', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                summary.formattedSavings,
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Box Hutang Piutang
                  Expanded(
                    child: summaryAsync.when(
                      data: (summary) => GlassCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => onNavigateTab(3), // Hutang
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.handshake_rounded, color: AppTheme.accentAmber, size: 18),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Sisa Hutang Saya', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                summary.formattedDebt,
                                style: GoogleFonts.outfit(color: AppTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Header Transaksi Terbaru & Lihat Semua
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi Terbaru',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(1), // Transaksi
                    child: Text('Lihat Semua', style: GoogleFonts.outfit(color: AppTheme.accentEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // List Transaksi Terbaru
              transactionsAsync.when(
                data: (txs) {
                  if (txs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 40),
                          const SizedBox(height: 10),
                          Text('Belum ada transaksi di bulan ini', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  final recent = txs.take(6).toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final tx = recent[i];
                      return _buildTransactionTile(context, tx);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Gagal memuat transaksi'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (tx.category?.color ?? AppTheme.accentEmerald).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tx.category?.iconData ?? Icons.receipt_rounded, color: tx.category?.color ?? AppTheme.accentEmerald, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category?.name ?? (tx.isIncome ? 'Pemasukan' : 'Pengeluaran'),
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.note != null && tx.note!.isNotEmpty ? '${tx.formattedShortDate} • ${tx.note}' : tx.formattedShortDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} ${tx.formattedAmount}',
            style: GoogleFonts.outfit(
              color: tx.isIncome ? AppTheme.accentEmerald : AppTheme.accentRose,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
