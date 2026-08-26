import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/debt_modals.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final summaryAsync = ref.watch(financialSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Hutang & Piutang',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddDebtModal.show(context, type: _tabController.index == 0 ? 'hutang' : 'piutang'),
        backgroundColor: _tabController.index == 0 ? AppTheme.redMain : AppTheme.bluePrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          _tabController.index == 0 ? '+ Catat Hutang' : '+ Catat Piutang',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Dual Metric Summary (Hutang Saya vs Piutang Orang)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: summaryAsync.when(
                data: (summary) => Row(
                  children: [
                    // Box Total Hutang Saya
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(color: AppTheme.redMain.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppTheme.redSoft, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.redMain, size: 14),
                                ),
                                const SizedBox(width: 6),
                                Text('Hutang Saya', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                summary.formattedDebt,
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.redMain, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Wajib Dilunasi', style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Box Total Piutang Orang
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(color: AppTheme.bluePrimary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppTheme.blueLight, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.bluePrimary, size: 14),
                                ),
                                const SizedBox(width: 6),
                                Text('Piutang Orang', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                summary.formattedReceivable,
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Harus Ditagih', style: GoogleFonts.plusJakartaSans(color: AppTheme.textLight, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 6),

            // 2. Tab Bar Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _tabController.index == 0 ? AppTheme.redMain : AppTheme.bluePrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                  onTap: (_) => setState(() {}),
                  tabs: const [
                    Tab(text: 'Hutang Saya (Wajib Bayar)'),
                    Tab(text: 'Piutang Orang (Harus Ditagih)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. TabBarView Lists
            Expanded(
              child: debtsAsync.when(
                data: (allDebts) {
                  final myDebts = allDebts.where((d) => d.isDebt).toList();
                  final myReceivables = allDebts.where((d) => d.isReceivable).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtList(context, ref, myDebts, isDebt: true),
                      _buildDebtList(context, ref, myReceivables, isDebt: false),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Gagal memuat data hutang piutang')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(BuildContext context, WidgetRef ref, List<DebtModel> list, {required bool isDebt}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 120;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDebt ? Icons.check_circle_outline_rounded : Icons.handshake_outlined, color: AppTheme.textLight, size: 64),
            const SizedBox(height: 16),
            Text(
              isDebt ? 'Tidak ada tanggungan hutang' : 'Tidak ada piutang yang tercatat',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isDebt ? 'Keuangan Anda bebas dari catatan hutang aktif!' : 'Catat uang Anda yang dipinjam teman atau pihak lain.',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = list[i];
        return _buildDebtCard(context, ref, item, isDebt: isDebt);
      },
    );
  }

  Widget _buildDebtCard(BuildContext context, WidgetRef ref, DebtModel item, {required bool isDebt}) {
    final mainColor = isDebt ? AppTheme.redMain : AppTheme.bluePrimary;
    final softColor = isDebt ? AppTheme.redSoft : AppTheme.blueLight;
    final percent = (item.progressPercentage * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Orang, Kategori & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isSettled ? AppTheme.greenSoft : softColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isSettled ? Icons.check_circle_rounded : (isDebt ? Icons.person_rounded : Icons.account_balance_wallet_rounded),
                  color: item.isSettled ? AppTheme.greenMain : mainColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.debtorName,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      item.categoryDebt,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isSettled ? AppTheme.greenSoft : softColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.isSettled ? 'LUNAS 🎉' : 'BELUM LUNAS ($percent%)',
                  style: GoogleFonts.plusJakartaSans(
                    color: item.isSettled ? AppTheme.greenMain : mainColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nominal: Sisa vs Total Awal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDebt ? 'Sisa Hutang Wajib Bayar' : 'Sisa Piutang Harus Ditagih',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  Text(
                    item.formattedRemaining,
                    style: GoogleFonts.plusJakartaSans(
                      color: item.isSettled ? AppTheme.greenMain : mainColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Nominal Awal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                  Text(
                    item.formattedTotal,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar Pelunasan
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.progressPercentage,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(item.isSettled ? AppTheme.greenMain : mainColor),
            ),
          ),
          const SizedBox(height: 14),

          // Info Jatuh Tempo & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_outlined, color: AppTheme.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Tenggat: ${item.formattedDueDate}',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppTheme.cardBg,
                          title: const Text('Hapus Catatan?'),
                          content: Text('Hapus catatan ${isDebt ? 'hutang' : 'piutang'} ${item.debtorName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redMain),
                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(financialControllerProvider.notifier).deleteDebt(item.id!);
                      }
                    },
                  ),
                  if (!item.isSettled) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => PayDebtModal.show(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDebt ? AppTheme.redMain : AppTheme.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(isDebt ? Icons.payment_rounded : Icons.archive_rounded, size: 15),
                      label: Text(
                        isDebt ? 'Bayar Cicilan' : 'Terima Bayaran',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
