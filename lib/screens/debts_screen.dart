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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddDebtModal.show(context, type: _selectedType),
        backgroundColor: _selectedType == 'hutang' ? AppTheme.redMain : AppTheme.greenMain,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Catat ${_selectedType == 'hutang' ? 'Hutang' : 'Piutang'}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
        ),
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
                data: (summary) => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total Hutang Saya Box
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
                                  'TOTAL HUTANG SAYA',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
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
                                  'TOTAL PIUTANG SAYA',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              _buildBillingStatusBadge(item),
            ],
          ),
          const SizedBox(height: 10),

          // Debtor Name
          Text(
            item.debtorName,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),

          // Dates & Recurring Due Date Badge
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Tgl Pinjam: ${AppDateFormatter.formatShort(item.borrowDate)}',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
              ),
              if (item.dueDay > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDebt ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDebt ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_repeat_rounded, size: 10.5, color: isDebt ? AppTheme.redMain : AppTheme.bluePrimary),
                      const SizedBox(width: 3),
                      Text(
                        'Tiap tgl ${item.dueDay}',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDebt ? AppTheme.redMain : AppTheme.bluePrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.dueDate != null) ...[
                const SizedBox(width: 4),
                Text(
                  '• Jatuh Tempo: ${AppDateFormatter.formatShort(item.dueDate!)}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),

          // Monthly Installment Banner (if installment mode)
          if (item.calculatedMonthlyInstallment > 0 || item.tenorMonths > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        item.tenorMonths > 0 ? 'Cicilan (${item.tenorMonths}x):' : 'Cicilan:',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.formattedMonthlyInstallment} / bln',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ],
                  ),
                  if (item.dueDate != null)
                    Text(
                      'Lunas: ${AppDateFormatter.formatMonthYear(item.dueDate!)}',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ],

          // Monthly Overdue Warning Banner
          if (item.currentMonthBillingStatus == 'overdue') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.redMain, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠️ Peringatan: Jatuh tempo tanggal ${item.dueDay > 0 ? item.dueDay : item.dueDate?.day} bulan ini sudah lewat dan belum ada pembayaran yang dicatat!',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF991B1B), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (item.hasPaidThisMonth && !item.isSettled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tagihan bulan ini aman! Pembayaran sebesar ${CurrencyFormatter.formatRupiah(item.paidThisMonthAmount)} telah dicatat.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF065F46), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

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

          // Action Buttons (Bayar Cicilan/Terima Bayar, Log Cicilan, Hapus)
          Row(
            children: [
              if (!isLunas) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => PayDebtModal.show(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDebt ? AppTheme.bluePrimary : AppTheme.greenMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.paid_rounded, size: 15, color: Colors.white),
                    label: Text(
                      isDebt ? 'Bayar Cicilan' : 'Terima Bayar',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentHistoryModal(context, item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderLight),
                    backgroundColor: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 15, color: AppTheme.bluePrimary),
                  label: Text(
                    'Log (${item.payments.length})',
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
                            const Text('Hapus Catatan?'),
                          ],
                        ),
                        content: Text(
                          'Yakin ingin menghapus catatan ${isDebt ? 'hutang' : 'piutang'} "${item.debtorName}"?',
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
                      ref.read(financialControllerProvider.notifier).deleteDebt(item.id!);
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

  Widget _buildBillingStatusBadge(DebtModel item) {
    final billingStatus = item.currentMonthBillingStatus;

    if (item.isSettled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.greenSoft, borderRadius: BorderRadius.circular(8)),
        child: Text('LUNAS', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }

    if (item.hasPaidThisMonth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
            const SizedBox(width: 4),
            Text('Bulan Ini Aman ✅', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10.5)),
          ],
        ),
      );
    }

    if (billingStatus == 'overdue') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.redMain),
            const SizedBox(width: 4),
            Text('Lewat Jatuh Tempo ⚠️', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 10.5)),
          ],
        ),
      );
    }

    if (billingStatus == 'due_soon') {
      final daysLeft = (item.dueDay > 0 ? item.dueDay : (item.dueDate?.day ?? 15)) - DateTime.now().day;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(daysLeft == 0 ? 'Jatuh Tempo Hari Ini!' : 'Jatuh Tempo H-$daysLeft', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 10.5)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Text('Belum Lunas', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
