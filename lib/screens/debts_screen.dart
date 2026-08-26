import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/debt_modals.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _selectedType = 'hutang'; // 'hutang' atau 'piutang'
  String _statusFilter = 'belum_lunas'; // 'belum_lunas', 'lunas', 'all'

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kartu Kredit':
        return Icons.credit_card_rounded;
      case 'Pinjaman Bank':
        return Icons.account_balance_rounded;
      case 'Leasing / Kendaraan':
        return Icons.directions_car_rounded;
      case 'Pinjaman Online':
        return Icons.phone_android_rounded;
      case 'Perorangan / Teman':
        return Icons.person_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _showPaymentHistoryModal(BuildContext context, DebtModel debt) {
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
                    'Riwayat Cicilan & Pembayaran',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${debt.payments.length} Kali',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Text(
                '${debt.debtorName} • Total: ${debt.formattedTotal}',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              if (debt.payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text('Belum ada riwayat pembayaran/cicilan.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13)),
                )
              else
                ...debt.payments.map((p) => Container(
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
                          Text(p.formattedDate, style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (p.note != null && p.note!.isNotEmpty)
                            Text(p.note!, style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                      Text(
                        p.formattedAmount,
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
  );
}

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final summaryAsync = ref.watch(financialSummaryProvider);

    final bottomPadding = MediaQuery.of(context).padding.bottom + 160;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          'Debt & Credit Manager',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
        actions: [
          IconButton(
            onPressed: () => AddDebtModal.show(context, type: _selectedType),
            icon: const Icon(Icons.add_circle_rounded, color: AppTheme.bluePrimary, size: 26),
            tooltip: 'Tambah Catatan',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catat kartu kredit, bank, pinjaman & pelunasan',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // 1. Segmented Tab Switcher (Hutang Saya vs Piutang di Orang)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'hutang'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedType == 'hutang' ? AppTheme.redMain : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Hutang Saya',
                            style: GoogleFonts.plusJakartaSans(
                              color: _selectedType == 'hutang' ? Colors.white : AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'piutang'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedType == 'piutang' ? AppTheme.greenMain : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Piutang (Di Orang)',
                            style: GoogleFonts.plusJakartaSans(
                              color: _selectedType == 'piutang' ? Colors.white : AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Dual Summary Cards Side-by-Side
              summaryAsync.when(
                data: (summary) => Row(
                  children: [
                    // Total Hutang Saya Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                          children: [
                            Text(
                              'TOTAL HUTANG SAYA',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                summary.formattedDebt,
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.redMain, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kartu Kredit, Bank, dll',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Total Piutang Saya Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
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
                          children: [
                            Text(
                              'TOTAL PIUTANG SAYA',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                summary.formattedReceivable,
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.greenMain, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Uang di Orang Lain',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),

              // 3. Status Filter Pills
              Row(
                children: [
                  _buildStatusPill('Belum Lunas', 'belum_lunas'),
                  const SizedBox(width: 8),
                  _buildStatusPill('Lunas', 'lunas'),
                  const SizedBox(width: 8),
                  _buildStatusPill('Semua Data', 'all'),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Section Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAFTAR ${_selectedType.toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  InkWell(
                    onTap: () => AddDebtModal.show(context, type: _selectedType),
                    child: Text(
                      '+ Catat ${_selectedType == 'hutang' ? 'Hutang' : 'Piutang'}',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Debt List Items
              debtsAsync.when(
                data: (allDebts) {
                  var filtered = allDebts.where((d) => d.type == _selectedType).toList();
                  if (_statusFilter == 'belum_lunas') {
                    filtered = filtered.where((d) => !d.isSettled).toList();
                  } else if (_statusFilter == 'lunas') {
                    filtered = filtered.where((d) => d.isSettled).toList();
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
                          const Icon(Icons.receipt_long_outlined, color: AppTheme.textLight, size: 44),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada catatan ${_selectedType == 'hutang' ? 'hutang' : 'piutang'}.',
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
                      final item = filtered[i];
                      return _buildDebtCardItem(context, ref, item);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Gagal memuat data')),
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

  Widget _buildDebtCardItem(BuildContext context, WidgetRef ref, DebtModel item) {
    final isDebt = item.isDebt;
    final isLunas = item.isSettled;
    final paidAmount = item.totalAmount - item.remainingAmount;
    final progressInt = (item.progressPercentage * 100).toInt();
    final katIcon = _getCategoryIcon(item.categoryDebt);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Tag & Lunas Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(katIcon, size: 13, color: AppTheme.bluePrimary),
                    const SizedBox(width: 4),
                    Text(
                      item.categoryDebt,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLunas ? AppTheme.greenSoft : AppTheme.redSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLunas ? 'LUNAS' : 'Belum Lunas',
                  style: GoogleFonts.plusJakartaSans(
                    color: isLunas ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Debtor Name
          Text(
            item.debtorName,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),

          // Dates
          Text(
            'Tgl Pinjam: ${AppDateFormatter.formatShort(item.borrowDate)}${item.dueDate != null ? " • Jatuh Tempo: ${AppDateFormatter.formatShort(item.dueDate!)}" : ""}',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Total vs Sisa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total: ${item.formattedTotal}',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Sisa: ${item.formattedRemaining}',
                style: GoogleFonts.plusJakartaSans(
                  color: isDebt ? AppTheme.redMain : AppTheme.greenMain,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar Pelunasan
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.progressPercentage,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(isLunas ? AppTheme.greenMain : AppTheme.bluePrimary),
            ),
          ),
          const SizedBox(height: 4),

          // Subtext Progress
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Terbayar ${CurrencyFormatter.formatRupiah(paidAmount)} ($progressInt%)',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),

          // Note Box (if any)
          if (item.note != null && item.note!.isNotEmpty) ...[
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
                item.note!,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textBody, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 10),

          // Action Buttons matching www/Keuangan (Bayar Cicilan, Log Cicilan, Delete)
          Row(
            children: [
              if (!isLunas) ...[
                ElevatedButton.icon(
                  onPressed: () => PayDebtModal.show(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: Text(
                    'Bayar Cicilan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _showPaymentHistoryModal(context, item),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderLight),
                  backgroundColor: AppTheme.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.history_rounded, size: 16, color: AppTheme.bluePrimary),
                label: Text(
                  'Log Cicilan (${item.payments.length})',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.redMain, size: 20),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppTheme.cardBg,
                      title: const Text('Hapus Catatan?'),
                      content: Text('Hapus catatan ${isDebt ? 'hutang' : 'piutang'} "${item.debtorName}"?'),
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
            ],
          ),
        ],
      ),
    );
  }
}
