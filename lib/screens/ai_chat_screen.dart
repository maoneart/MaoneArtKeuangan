import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/debt_model.dart';
import '../models/saving_model.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';
import 'api_key_tutorial_screen.dart';

class ChatBubbleMessage {
  final String sender; // 'user' atau 'ai'
  final String text;
  final List<ParsedTransaction> detectedTransactions;
  final DateTime timestamp;
  final bool isError;

  ChatBubbleMessage({
    required this.sender,
    required this.text,
    this.detectedTransactions = const [],
    required this.timestamp,
    this.isError = false,
  });
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatBubbleMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatBubbleMessage(
        sender: 'ai',
        text: 'Halo! Saya **MaoneArt AI Assistant** 🤖✨\n\nAnda bisa curhat tentang segala hal seputar keuangan Anda:\n• 💸 **Pemasukan & Pengeluaran** *(misal: "Makan siang 25rb & bensin 30rb")*\n• 🤝 **Hutang & Piutang** *(misal: "Pinjam uang ke Budi 500rb")*\n• 🎯 **Target Tabungan & Setoran** *(misal: "Bikin target nabung beli HP 3jt")*\n\nSemua akan otomatis saya rangkum dan bisa langsung Anda simpan dengan 1 klik!',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(
        ChatBubbleMessage(
          sender: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final savings = ref.read(savingsProvider).valueOrNull ?? [];
    final debts = ref.read(debtsProvider).valueOrNull ?? [];
    final summary = ref.read(financialSummaryProvider).valueOrNull;

    // Riwayat percakapan terakhir
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.sender == 'user' ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    final response = await GeminiService.sendMessage(
      userMessage: text,
      categories: categories,
      existingDebts: debts,
      existingSavings: savings,
      summary: summary,
      history: history,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatBubbleMessage(
            sender: 'ai',
            text: response.replyText,
            detectedTransactions: response.detectedTransactions,
            timestamp: DateTime.now(),
            isError: response.isError,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _saveTransactions(List<ParsedTransaction> txs, List<CategoryModel> categories, List<SavingModel> savings, List<DebtModel> debts) async {
    int savedCount = 0;
    for (final tx in txs) {
      if (!tx.isSaved) {
        if (tx.type == 'pemasukan' || tx.type == 'pengeluaran') {
          // 1. Simpan Transaksi Arus Kas
          int catId = tx.categoryId ?? 1;
          if (tx.categoryId == null) {
            final matched = categories.firstWhere(
              (c) => c.name.toLowerCase().contains(tx.categoryName.toLowerCase()) ||
                  tx.categoryName.toLowerCase().contains(c.name.toLowerCase()),
              orElse: () => categories.firstWhere(
                (c) => c.type == tx.type,
                orElse: () => categories.first,
              ),
            );
            catId = matched.id ?? 1;
          }

          final newTx = TransactionModel(
            date: tx.date,
            type: tx.type,
            categoryId: catId,
            amount: tx.amount,
            note: tx.note,
          );

          await ref.read(financialControllerProvider.notifier).addTransaction(newTx);
          tx.isSaved = true;
          savedCount++;
        } else if (tx.type == 'bayar_hutang') {
          // 2. Bayar Cicilan / Pelunasan Hutang
          DebtModel? targetDebt;
          if (debts.isNotEmpty) {
            if (tx.personName != null && tx.personName!.isNotEmpty) {
              targetDebt = debts.firstWhere(
                (d) => d.isDebt && (d.debtorName.toLowerCase().contains(tx.personName!.toLowerCase()) ||
                    tx.personName!.toLowerCase().contains(d.debtorName.toLowerCase())),
                orElse: () => debts.firstWhere((d) => d.isDebt && !d.isSettled, orElse: () => debts.first),
              );
            } else {
              targetDebt = debts.firstWhere((d) => d.isDebt && !d.isSettled, orElse: () => debts.first);
            }
          }

          if (targetDebt != null && targetDebt.id != null) {
            await ref.read(financialControllerProvider.notifier).payDebt(
              targetDebt.id!,
              tx.amount,
              tx.date,
              note: tx.note,
            );
          } else {
            final matchedCat = categories.firstWhere(
              (c) => c.name.toLowerCase().contains('hutang') || c.name.toLowerCase().contains('tagihan'),
              orElse: () => categories.firstWhere((c) => c.type == 'pengeluaran', orElse: () => categories.first),
            );
            final newTx = TransactionModel(
              date: tx.date,
              type: 'pengeluaran',
              categoryId: matchedCat.id ?? 1,
              amount: tx.amount,
              note: tx.note,
            );
            await ref.read(financialControllerProvider.notifier).addTransaction(newTx);
          }
          tx.isSaved = true;
          savedCount++;
        } else if (tx.type == 'hutang' || tx.type == 'piutang') {
          // 3. Simpan Hutang atau Piutang Baru
          final newDebt = DebtModel(
            debtorName: tx.personName != null && tx.personName!.isNotEmpty ? tx.personName! : 'Rekan / Pihak Lain',
            type: tx.type,
            totalAmount: tx.amount,
            remainingAmount: tx.amount,
            borrowDate: tx.date,
            dueDate: tx.dueDate,
            tenorMonths: tx.tenorMonths,
            dueDay: tx.dueDay,
            monthlyInstallment: tx.monthlyInstallment,
            note: tx.note,
          );

          await ref.read(financialControllerProvider.notifier).addDebt(newDebt);
          tx.isSaved = true;
          savedCount++;
        } else if (tx.type == 'target_tabungan') {
          // 4. Buat Target Impian Tabungan Baru
          final newSaving = SavingModel(
            name: tx.targetName != null && tx.targetName!.isNotEmpty ? tx.targetName! : 'Tabungan Impian',
            targetAmount: (tx.targetAmount != null && tx.targetAmount! > 0) ? tx.targetAmount! : tx.amount,
            collectedAmount: 0.0,
            note: tx.note,
          );

          await ref.read(financialControllerProvider.notifier).addSaving(newSaving);
          tx.isSaved = true;
          savedCount++;
        } else if (tx.type == 'setoran_tabungan') {
          // 5. Setor ke Tabungan yang Ada
          SavingModel? targetSaving;
          if (savings.isNotEmpty) {
            targetSaving = savings.firstWhere(
              (s) => tx.targetName != null && (s.name.toLowerCase().contains(tx.targetName!.toLowerCase()) ||
                  tx.targetName!.toLowerCase().contains(s.name.toLowerCase())),
              orElse: () => savings.first,
            );
          }

          if (targetSaving != null && targetSaving.id != null) {
            await ref.read(financialControllerProvider.notifier).depositSaving(
              targetSaving.id!,
              tx.amount,
              tx.date,
              note: tx.note,
            );
          } else {
            // Jika belum ada target, buat target baru lalu setorkan
            final newSaving = SavingModel(
              name: tx.targetName != null && tx.targetName!.isNotEmpty ? tx.targetName! : 'Tabungan Impian',
              targetAmount: tx.amount * 5,
              collectedAmount: tx.amount,
              note: tx.note,
            );
            await ref.read(financialControllerProvider.notifier).addSaving(newSaving);
          }
          tx.isSaved = true;
          savedCount++;
        }
      }
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount catatan berhasil disimpan ke database keuangan! 🎉'),
          backgroundColor: AppTheme.greenMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final savings = ref.watch(savingsProvider).valueOrNull ?? [];
    final debts = ref.watch(debtsProvider).valueOrNull ?? [];
    final savedApiKey = ref.watch(geminiApiKeyProvider);
    final hasApiKey = savedApiKey.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF0047CC)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MaoneArt AI Assistant',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
                Text(
                  'Curhat Transaksi, Hutang & Tabungan',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
            ),
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1)),
            tooltip: 'Panduan API Key',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.key_rounded, color: AppTheme.bluePrimary),
            tooltip: 'Atur API Key',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatBubbleMessage(
                    sender: 'ai',
                    text: 'Percakapan telah dibersihkan. Silakan ceritakan transaksi, hutang, atau tabungan apa saja!',
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            tooltip: 'Bersihkan Chat',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner if API Key is not configured
            if (!hasApiKey)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gemini API Key belum dimasukkan. Dapatkan kunci gratis dan masukkan di Pengaturan.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ApiKeyTutorialScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF92400E),
                        side: const BorderSide(color: Color(0xFFD97706)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Tutorial', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Isi Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  final isUser = msg.sender == 'user';
                  return _buildChatBubble(msg, isUser, categories, savings, debts);
                },
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bluePrimary)),
                    const SizedBox(width: 10),
                    Text(
                      'AI sedang menganalisis curhat Anda...',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Suggestion Chips
            if (_messages.length <= 2 && !_isLoading)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildSuggestionChip('🍜 Makan siang 25rb & bensin 30rb'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('🤝 Pinjam uang ke Budi 500rb'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('📱 Bikin target nabung HP 3jt'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('💰 Setor 100rb tabungan HP'),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? bottomInset + 8 : bottomSafe + 16),
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14),
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Curhat transaksi, hutang, atau tabungan...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.royalBlueGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : () => _sendMessage(),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textDark)),
      backgroundColor: AppTheme.cardBg,
      side: const BorderSide(color: AppTheme.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildChatBubble(ChatBubbleMessage msg, bool isUser, List<CategoryModel> categories, List<SavingModel> savings, List<DebtModel> debts) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.bluePrimary : AppTheme.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  color: isUser ? Colors.white : AppTheme.textDark,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),

            // Detected Transactions Action Card
            if (!isUser && msg.detectedTransactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${msg.detectedTransactions.length} CATATAN TERDETEKSI',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final tx in msg.detectedTransactions)
                        _buildDetectedTransactionItem(tx),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: msg.detectedTransactions.every((t) => t.isSaved)
                              ? null
                              : () => _saveTransactions(msg.detectedTransactions, categories, savings, debts),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.greenMain,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: AppTheme.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: Icon(
                            msg.detectedTransactions.every((t) => t.isSaved)
                                ? Icons.check_circle_rounded
                                : Icons.save_rounded,
                            size: 16,
                          ),
                          label: Text(
                            msg.detectedTransactions.every((t) => t.isSaved)
                                ? 'Semua Catatan Telah Disimpan ✅'
                                : 'Simpan ke Catatan Keuangan',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedTransactionItem(ParsedTransaction tx) {
    IconData iconData;
    Color iconColor;
    Color iconBg;
    String badgeLabel;
    String mainTitle;
    String subTitle;
    String amountPrefix;
    double displayAmount = tx.amount;

    if (tx.type == 'pemasukan') {
      iconData = Icons.arrow_downward_rounded;
      iconColor = AppTheme.greenMain;
      iconBg = AppTheme.greenSoft;
      badgeLabel = 'Pemasukan';
      mainTitle = tx.note;
      subTitle = tx.categoryName;
      amountPrefix = '+';
    } else if (tx.type == 'pengeluaran') {
      iconData = Icons.arrow_upward_rounded;
      iconColor = AppTheme.redMain;
      iconBg = AppTheme.redSoft;
      badgeLabel = 'Pengeluaran';
      mainTitle = tx.note;
      subTitle = tx.categoryName;
      amountPrefix = '-';
    } else if (tx.type == 'bayar_hutang') {
      iconData = Icons.receipt_long_rounded;
      iconColor = AppTheme.redMain;
      iconBg = AppTheme.redSoft;
      badgeLabel = 'Bayar Hutang';
      mainTitle = 'Bayar ke ${tx.personName ?? "Pemberi Pinjaman"}';
      subTitle = tx.note;
      amountPrefix = '-';
    } else if (tx.type == 'hutang') {
      iconData = Icons.handshake_rounded;
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
      badgeLabel = 'Hutang Saya';
      mainTitle = 'Hutang ke ${tx.personName ?? "Pihak Lain"}';
      subTitle = tx.note;
      amountPrefix = '';
    } else if (tx.type == 'piutang') {
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = AppTheme.bluePrimary;
      iconBg = AppTheme.blueLight;
      badgeLabel = 'Piutang';
      mainTitle = 'Piutang di ${tx.personName ?? "Pihak Lain"}';
      subTitle = tx.note;
      amountPrefix = '';
    } else if (tx.type == 'target_tabungan') {
      iconData = Icons.savings_rounded;
      iconColor = const Color(0xFF8B5CF6);
      iconBg = const Color(0xFFEDE9FE);
      badgeLabel = 'Target Tabungan';
      mainTitle = tx.targetName ?? 'Target Impian';
      subTitle = tx.note;
      amountPrefix = 'Target ';
      displayAmount = tx.targetAmount != null && tx.targetAmount! > 0 ? tx.targetAmount! : tx.amount;
    } else {
      // setoran_tabungan
      iconData = Icons.add_circle_rounded;
      iconColor = const Color(0xFF059669);
      iconBg = const Color(0xFFD1FAE5);
      badgeLabel = 'Setoran Tabungan';
      mainTitle = 'Setor ke ${tx.targetName ?? "Tabungan"}';
      subTitle = tx.note;
      amountPrefix = '+';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.plusJakartaSans(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 8.5, color: Color(0xFF64748B)),
                          const SizedBox(width: 2.5),
                          Text(
                            AppDateFormatter.formatShort(tx.date),
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 8.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        mainTitle,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subTitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${CurrencyFormatter.formatRupiah(displayAmount)}',
            style: GoogleFonts.plusJakartaSans(
              color: iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
