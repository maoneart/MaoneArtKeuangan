import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saving_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/saving_modals.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String _statusFilter = 'berlangsung'; // 'berlangsung', 'tercapai', 'all'

  void _showDepositHistoryModal(BuildContext context, SavingModel saving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Setoran Tabungan',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${saving.deposits.length} Kali',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    '${saving.name} • Target: ${saving.formattedTarget}',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  if (saving.deposits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text('Belum ada riwayat setoran.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                    )
                  else
                    ...saving.deposits.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.formattedDate, style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                              if (d.note != null && d.note!.isNotEmpty)
                                Text(d.note!, style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                          Text(
                            d.formattedAmount,
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsAsync = ref.watch(savingsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 160;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Savings & Target Goals',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSavingModal.show(context),
        backgroundColor: AppTheme.bluePrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Buat Target Impian', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rencanakan target impian & tabung secara berkala',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // 1. Dual Summary Cards Side-by-Side (Matching www/Keuangan)
              savingsAsync.when(
                data: (savings) {
                  final totalTerkumpul = savings.fold<double>(0.0, (sum, s) => sum + s.collectedAmount);
                  final totalTargetAktif = savings.where((s) => !s.isAchieved).fold<double>(0.0, (sum, s) => sum + s.targetAmount);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Tabungan Terkumpul Box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0047CC).withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 26,
                                  child: Text(
                                    'TOTAL TERKUMPUL',
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.formatRupiah(totalTerkumpul),
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dana Terkumpul',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Target Tabungan Aktif Box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0047CC).withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 26,
                                  child: Text(
                                    'TARGET AKTIF',
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.formatRupiah(totalTargetAktif),
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Impian Berlangsung',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),

              // 2. Status Filter Pills
              Row(
                children: [
                  _buildStatusPill('Berlangsung', 'berlangsung'),
                  const SizedBox(width: 8),
                  _buildStatusPill('Tercapai 🎉', 'tercapai'),
                  const SizedBox(width: 8),
                  _buildStatusPill('Semua Target', 'all'),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Section Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TARGET TABUNGAN IMPIAN',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  InkWell(
                    onTap: () => AddSavingModal.show(context),
                    child: Text(
                      '+ Buat Target Baru',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. Savings List
              savingsAsync.when(
                data: (savings) {
                  var filtered = savings;
                  if (_statusFilter == 'berlangsung') {
                    filtered = savings.where((s) => !s.isAchieved).toList();
                  } else if (_statusFilter == 'tercapai') {
                    filtered = savings.where((s) => s.isAchieved).toList();
                  }

                  if (filtered.isEmpty) {
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
                          const Icon(Icons.savings_outlined, color: AppTheme.textLight, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada target tabungan impian.',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final saving = filtered[i];
                      return _buildSavingCardItem(context, ref, saving);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Gagal memuat tabungan')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, String value) {
    final isSelected = _statusFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.bluePrimary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.bluePrimary : AppTheme.borderLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSavingCardItem(BuildContext context, WidgetRef ref, SavingModel saving) {
    final isAchieved = saving.isAchieved;
    final progressInt = (saving.progressPercentage * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Badge & Target Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAchieved ? AppTheme.greenSoft : AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAchieved ? 'TERCAPAI 🎉' : 'Berlangsung',
                  style: GoogleFonts.plusJakartaSans(
                    color: isAchieved ? const Color(0xFF047857) : AppTheme.bluePrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            saving.name,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),

          Text(
            'Target Selesai: ${saving.formattedDueDate}',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Terkumpul vs Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                saving.formattedCollected,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                'Target: ${saving.formattedTarget}',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: saving.progressPercentage,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(isAchieved ? AppTheme.greenMain : const Color(0xFF059669)),
            ),
          ),
          const SizedBox(height: 4),

          // Subtext Progress
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Terkumpul $progressInt%',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),

          // Note Box (if any)
          if (saving.note != null && saving.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                saving.note!,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textBody, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 10),

          // Action Buttons (Setor Tabungan, Log Setoran, Hapus)
          Row(
            children: [
              if (!isAchieved) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => DepositSavingModal.show(context, saving),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_circle_rounded, size: 15, color: Colors.white),
                    label: Text(
                      'Setor Tabungan',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDepositHistoryModal(context, saving),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderLight),
                    backgroundColor: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 15, color: Color(0xFF059669)),
                  label: Text(
                    'Log (${saving.deposits.length})',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.redMain, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('Hapus Target?'),
                          ],
                        ),
                        content: Text(
                          'Yakin ingin menghapus target tabungan "${saving.name}"?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.redMain,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(financialControllerProvider.notifier).deleteSaving(saving.id!);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.redMain, size: 19),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
