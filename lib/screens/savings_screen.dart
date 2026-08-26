import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saving_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/saving_modals.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Tabungan & Impian',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSavingModal.show(context),
        backgroundColor: AppTheme.bluePrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Buat Target', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: savingsAsync.when(
          data: (savings) {
            if (savings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings_outlined, color: AppTheme.textLight, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada target tabungan',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buat target impian Anda (misal: Beli Gadget, Liburan, Dana Darurat)',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final bottomPadding = MediaQuery.of(context).padding.bottom + 160;
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              itemCount: savings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                final saving = savings[i];
                return _buildSavingCard(context, ref, saving);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Gagal memuat target tabungan')),
        ),
      ),
    );
  }

  Widget _buildSavingCard(BuildContext context, WidgetRef ref, SavingModel saving) {
    final percent = (saving.progressPercentage * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Target & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: saving.isAchieved ? AppTheme.greenSoft : AppTheme.blueLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  saving.isAchieved ? Icons.check_circle_rounded : Icons.savings_rounded,
                  color: saving.isAchieved ? AppTheme.greenMain : AppTheme.bluePrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saving.savingName,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Tenggat: ${saving.formattedTargetDate}',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: saving.isAchieved ? AppTheme.greenSoft : AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  saving.isAchieved ? 'TERCAPAI 🎉' : '$percent%',
                  style: GoogleFonts.plusJakartaSans(
                    color: saving.isAchieved ? AppTheme.greenMain : AppTheme.bluePrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nominal: Terkumpul vs Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo Terkumpul', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                  Text(
                    saving.formattedCollected,
                    style: GoogleFonts.plusJakartaSans(
                      color: saving.isAchieved ? AppTheme.greenMain : AppTheme.bluePrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target Akhir', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                  Text(
                    saving.formattedTarget,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: saving.progressPercentage,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(saving.isAchieved ? AppTheme.greenMain : AppTheme.bluePrimary),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa: ${saving.formattedRemaining}',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
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
                          title: const Text('Hapus Target?'),
                          content: Text('Hapus target tabungan "${saving.savingName}"?'),
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
                        ref.read(financialControllerProvider.notifier).deleteSaving(saving.id!);
                      }
                    },
                  ),
                  if (!saving.isAchieved) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => DepositSavingModal.show(context, saving),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                      label: Text(
                        'Setor Dana',
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
