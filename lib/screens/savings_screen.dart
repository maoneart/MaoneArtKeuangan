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
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Tabungan & Impian', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSavingModal.show(context),
        backgroundColor: AppTheme.accentCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Buat Target', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: savingsAsync.when(
          data: (savings) {
            if (savings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings_outlined, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text('Belum ada target tabungan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Buat target impian Anda (misal: Beli Gadget, Liburan, Dana Darurat)', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            final bottomPadding = MediaQuery.of(context).padding.bottom + 120;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  saving.name,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: saving.isAchieved ? AppTheme.accentEmerald.withValues(alpha: 0.2) : AppTheme.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: saving.isAchieved ? AppTheme.accentEmerald : AppTheme.accentCyan),
                ),
                child: Text(
                  saving.isAchieved ? 'TERCAPAI 🎉' : '$percent% Terkumpul',
                  style: GoogleFonts.outfit(
                    color: saving.isAchieved ? AppTheme.accentEmerald : AppTheme.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nominal: Terkumpul / Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dana Terkumpul', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(saving.formattedCollected, style: GoogleFonts.outfit(color: AppTheme.accentCyan, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target Akhir', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(saving.formattedTarget, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: saving.progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(saving.isAchieved ? AppTheme.accentEmerald : AppTheme.accentCyan),
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Tenggat & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tenggat: ${saving.formattedDueDate}',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppTheme.bgCard,
                          title: const Text('Hapus Target?'),
                          content: Text('Hapus target tabungan "${saving.name}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                            ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose), child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(financialControllerProvider.notifier).deleteSaving(saving.id!);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: saving.isAchieved ? null : () => DepositSavingModal.show(context, saving),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('+ Setor Dana', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
