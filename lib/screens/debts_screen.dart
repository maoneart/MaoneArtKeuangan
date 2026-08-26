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

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Hutang & Piutang', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentEmerald,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Hutang Saya (Wajib Bayar)'),
            Tab(text: 'Piutang Orang (Harus Ditagih)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddDebtModal.show(context, type: _tabController.index == 0 ? 'hutang' : 'piutang'),
        backgroundColor: _tabController.index == 0 ? AppTheme.accentRose : AppTheme.accentAmber,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(_tabController.index == 0 ? 'Catat Hutang' : 'Catat Piutang', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: debtsAsync.when(
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
    );
  }

  Widget _buildDebtList(BuildContext context, WidgetRef ref, List<DebtModel> list, {required bool isDebt}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDebt ? Icons.check_circle_outline_rounded : Icons.handshake_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              isDebt ? 'Tidak ada tanggungan hutang' : 'Tidak ada piutang yang tercatat',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isDebt ? 'Keuangan Anda bebas dari catatan hutang aktif!' : 'Catat uang Anda yang dipinjam teman atau pihak lain.',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = list[i];
        return _buildDebtCard(context, ref, item, isDebt: isDebt);
      },
    );
  }

  Widget _buildDebtCard(BuildContext context, WidgetRef ref, DebtModel item, {required bool isDebt}) {
    final color = isDebt ? AppTheme.accentRose : AppTheme.accentAmber;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.debtorName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(item.categoryDebt, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isSettled ? AppTheme.accentEmerald.withValues(alpha: 0.2) : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: item.isSettled ? AppTheme.accentEmerald : color),
                ),
                child: Text(
                  item.isSettled ? 'LUNAS' : 'BELUM LUNAS',
                  style: GoogleFonts.outfit(
                    color: item.isSettled ? AppTheme.accentEmerald : color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sisa ${isDebt ? 'Hutang' : 'Piutang'}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(item.formattedRemaining, style: GoogleFonts.outfit(color: item.isSettled ? AppTheme.accentEmerald : color, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Awal', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(item.formattedTotal, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jatuh Tempo: ${item.formattedDueDate}', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppTheme.bgCard,
                          title: const Text('Hapus Catatan?'),
                          content: Text('Hapus catatan ${isDebt ? 'hutang' : 'piutang'} ${item.debtorName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                            ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose), child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(financialControllerProvider.notifier).deleteDebt(item.id!);
                      }
                    },
                  ),
                  if (!item.isSettled)
                    ElevatedButton.icon(
                      onPressed: () => PayDebtModal.show(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentEmerald,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.payment_rounded, size: 15),
                      label: Text('Bayar / Cicil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
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
