import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/financial_summary.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/quick_add_modal.dart';
import 'category_management_screen.dart';
import 'debts_screen.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentMonth = ref.watch(selectedMonthProvider);

    final parts = currentMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final periodLabel = AppDateFormatter.formatMonthYear(monthDate);

    final bottomPadding = MediaQuery.of(context).padding.bottom + 160;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialSummaryProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(debtsProvider);
          ref.invalidate(savingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== 1. ROYAL BLUE HEADER BANNER (www/Keuangan Concept) ====================
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.royalBlueGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x380047CC),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Logo & App Title & Month Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: AppTheme.bluePrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MaoneArt Keuangan',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Catatan Keuangan Cerdas',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
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
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  periodLabel,
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Row 2: Total Balance Big Display
                    summaryAsync.when(
                      data: (summary) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance • Saldo Kas',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.formattedBalance,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Income & Expense Pills
                          Row(
                            children: [
                              // Pemasukan Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_downward_rounded, color: Color(0xFF6EE7B7), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      summary.formattedIncome,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Pengeluaran Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, color: Color(0xFFFCA5A5), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      summary.formattedExpense,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white))),
                      error: (_, __) => const Text('Gagal memuat saldo', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 22),

                    // Row 3: 4 Glassmorphic Action Buttons (Top Up, Bayar, Hutang, Tabungan)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGlassActionButton(
                          label: 'Top Up',
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => QuickAddModal.show(context, type: 'pemasukan'),
                        ),
                        _buildGlassActionButton(
                          label: 'Bayar',
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFF43F5E),
                          onTap: () => QuickAddModal.show(context, type: 'pengeluaran'),
                        ),
                        _buildGlassActionButton(
                          label: 'Hutang',
                          icon: Icons.handshake_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DebtsScreen())),
                        ),
                        _buildGlassActionButton(
                          label: 'Tabungan',
                          icon: Icons.savings_rounded,
                          color: const Color(0xFF06B6D4),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavingsScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==================== 2. APP FEATURES GRID (KATEGORI POPULER) ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'APP FEATURES',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
                      child: Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: categoriesAsync.when(
                  data: (cats) {
                    final featured = cats.take(8).toList();
                    final pastelColors = [
                      const Color(0xFFD1FAE5), // emerald soft
                      const Color(0xFFFEF3C7), // amber soft
                      const Color(0xFFEDE9FE), // purple soft
                      const Color(0xFFFCE7F3), // pink soft
                      const Color(0xFFDBEAFE), // blue soft
                      const Color(0xFFCCFBF1), // teal soft
                      const Color(0xFFE0E7FF), // indigo soft
                      const Color(0xFFF1F5F9), // slate soft
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: featured.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (ctx, i) {
                        final cat = featured[i];
                        final pastel = pastelColors[i % pastelColors.length];

                        return InkWell(
                          onTap: () => QuickAddModal.show(context, preSelectedCategory: cat, type: cat.type),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0047CC).withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: pastel,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(cat.iconData, color: cat.color, size: 22),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),

              // ==================== 3. LAST TRANSACTION SECTION ====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LAST TRANSACTION',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    InkWell(
                      onTap: () => onNavigateTab(1), // Navigasi ke transaksi
                      child: Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: transactionsAsync.when(
                  data: (txs) {
                    if (txs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: AppTheme.textLight, size: 40),
                            const SizedBox(height: 8),
                            Text('Belum ada riwayat transaksi.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    final recent = txs.take(6).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final tx = recent[i];
                        return _buildTransactionItem(context, tx);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Gagal memuat transaksi')),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (tx.category?.color ?? AppTheme.bluePrimary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tx.category?.iconData ?? Icons.receipt_rounded,
              color: tx.category?.color ?? AppTheme.bluePrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note != null && tx.note!.isNotEmpty ? tx.note! : (tx.category?.name ?? (tx.isIncome ? 'Pemasukan' : 'Pengeluaran')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.formattedShortDate} • ${tx.category?.name ?? "Umum"}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} ${tx.formattedAmount}',
            style: GoogleFonts.plusJakartaSans(
              color: tx.isIncome ? AppTheme.greenMain : AppTheme.redMain,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
