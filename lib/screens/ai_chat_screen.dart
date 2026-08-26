import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

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
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _messages.add(
      ChatBubbleMessage(
        sender: 'ai',
        text: 'Halo! Saya **MaoneArt AI Assistant** 🤖✨\n\nAnda bisa curhat tentang pengeluaran atau pemasukan hari ini (misal: *"Tadi makan siang 25rb dan beli bensin 30rb"*), dan saya akan otomatis merangkum serta mencatatkannya ke database keuangan Anda!',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _checkApiKey() async {
    final key = await GeminiService.getApiKey();
    if (mounted) {
      setState(() => _hasApiKey = key != null && key.trim().isNotEmpty);
    }
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

  void _saveTransactions(List<ParsedTransaction> txs, List<CategoryModel> categories) async {
    int savedCount = 0;
    for (final tx in txs) {
      if (!tx.isSaved) {
        // Cocokkan id kategori
        int? catId = tx.categoryId;
        if (catId == null) {
          final matched = categories.firstWhere(
            (c) => c.name.toLowerCase().contains(tx.categoryName.toLowerCase()) ||
                tx.categoryName.toLowerCase().contains(c.name.toLowerCase()),
            orElse: () => categories.firstWhere(
              (c) => c.type == tx.type,
              orElse: () => categories.first,
            ),
          );
          catId = matched.id;
        }

        final newTx = TransactionModel(
          date: DateTime.now(),
          type: tx.type,
          categoryId: catId,
          amount: tx.amount,
          note: tx.note,
        );

        await ref.read(financialControllerProvider.notifier).addTransaction(newTx);
        tx.isSaved = true;
        savedCount++;
      }
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount transaksi berhasil disimpan ke catatan keuangan! 🎉'),
          backgroundColor: AppTheme.greenMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
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
                  'Curhat Keuangan & Catat Otomatis',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _checkApiKey()),
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
                    text: 'Percakapan telah dibersihkan. Silakan ceritakan transaksi atau tanyakan apa saja seputar keuangan Anda!',
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
            if (!_hasApiKey)
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
                        'Gemini API Key belum dimasukkan. Masukkan API Key gratis Anda di menu Pengaturan.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ).then((_) => _checkApiKey()),
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
                  return _buildChatBubble(msg, isUser, categories);
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

            // Suggestion Chips (if few messages)
            if (_messages.length <= 2 && !_isLoading)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildSuggestionChip('🍜 Makan siang 25rb & bensin 30rb'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('💰 Dapat bonus transferan 500rb'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('💡 Beri tips hemat bulan ini'),
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
                          hintText: 'Ketik curhat keuangan Anda...',
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

  Widget _buildChatBubble(ChatBubbleMessage msg, bool isUser, List<CategoryModel> categories) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
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
            if (!isUser && msg.detectedTransactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${msg.detectedTransactions.length} TRANSAKSI TERDETEKSI',
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
                    ...msg.detectedTransactions.map((tx) {
                      final isIncome = tx.type == 'pemasukan';
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
                                color: isIncome ? AppTheme.greenSoft : AppTheme.redSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIncome ? AppTheme.greenMain : AppTheme.redMain,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.note,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
                                  ),
                                  Text(
                                    tx.categoryName,
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah(tx.amount)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: isIncome ? AppTheme.greenMain : AppTheme.redMain,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: msg.detectedTransactions.every((t) => t.isSaved)
                            ? null
                            : () => _saveTransactions(msg.detectedTransactions, categories),
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
                              ? 'Semua Transaksi Telah Disimpan ✅'
                              : 'Simpan ke Catatan Keuangan',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}
