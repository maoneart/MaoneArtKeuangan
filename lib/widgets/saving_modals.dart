import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saving_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class AddSavingModal extends ConsumerStatefulWidget {
  const AddSavingModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSavingModal(),
    );
  }

  @override
  ConsumerState<AddSavingModal> createState() => _AddSavingModalState();
}

class _AddSavingModalState extends ConsumerState<AddSavingModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _initialDepositController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialDepositController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(double currentBalance) async {
    final name = _nameController.text.trim();
    final target = CurrencyFormatter.parseRupiah(_targetController.text);
    final initialDeposit = CurrencyFormatter.parseRupiah(_initialDepositController.text);

    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama impian dan target nominal yang valid')),
      );
      return;
    }

    // Validasi Saldo Kas jika ada saldo awal
    if (initialDeposit > 0) {
      if (currentBalance < initialDeposit) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.redMain),
                SizedBox(width: 8),
                Text('Saldo Kas Kurang'),
              ],
            ),
            content: Text(
              'Saldo kas Anda saat ini (${CurrencyFormatter.formatRupiah(currentBalance)}) tidak mencukupi untuk setoran awal tabungan sebesar ${CurrencyFormatter.formatRupiah(initialDeposit)}.\n\nSilakan kurangi saldo awal atau catat pemasukan terlebih dahulu.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
            ],
          ),
        );
        return;
      }
    }

    final saving = SavingModel(
      name: name,
      targetAmount: target,
      collectedAmount: initialDeposit,
      dueDate: _dueDate,
      status: initialDeposit >= target ? 'tercapai' : 'berlangsung',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(financialControllerProvider.notifier).addSaving(saving);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initialDeposit > 0
                ? 'Target tabungan dibuat & Saldo Kas terpotong ${CurrencyFormatter.formatRupiah(initialDeposit)}!'
                : 'Target tabungan baru berhasil dibuat!',
          ),
          backgroundColor: AppTheme.bluePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currentBalance = summaryAsync.valueOrNull?.netBalance ?? 0.0;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
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
            bottom: bottomInset + bottomSafe + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BUAT TARGET TABUNGAN IMPIAN',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Cash Balance Indicator Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: currentBalance > 0 ? AppTheme.borderLight : AppTheme.redMain,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentBalance > 0 ? Icons.account_balance_wallet_rounded : Icons.error_outline_rounded,
                        color: currentBalance > 0 ? AppTheme.greenMain : AppTheme.redMain,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Kas Anda: ${CurrencyFormatter.formatRupiah(currentBalance)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: currentBalance > 0 ? AppTheme.textDark : AppTheme.redMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Pengisian Saldo Awal akan otomatis memotong Saldo Kas Anda',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nama Tabungan
                Text('NAMA TARGET IMPIAN', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Beli Laptop Baru, Liburan ke Bali...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  ),
                ),
                const SizedBox(height: 14),

                // Symmetrical Target Nominal Box with "Rp"
                Text('TARGET JUMLAH DANA (RP)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.bluePrimary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 24, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: AppTheme.textLight),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Saldo Awal & Tenggat Waktu
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SALDO AWAL (RP)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                Text('Rp', style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _initialDepositController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '0',
                                      hintStyle: TextStyle(color: AppTheme.textLight),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TARGET TANGGAL', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 90)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _dueDate = picked);
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _dueDate != null ? AppDateFormatter.formatShort(_dueDate!) : 'Pilih Tanggal',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _dueDate != null ? AppTheme.bluePrimary : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Catatan
                TextField(
                  controller: _noteController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Keterangan tambahan...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => _submit(currentBalance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Simpan Target Impian', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DepositSavingModal extends ConsumerStatefulWidget {
  final SavingModel saving;

  const DepositSavingModal({super.key, required this.saving});

  static Future<void> show(BuildContext context, SavingModel saving) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositSavingModal(saving: saving),
    );
  }

  @override
  ConsumerState<DepositSavingModal> createState() => _DepositSavingModalState();
}

class _DepositSavingModalState extends ConsumerState<DepositSavingModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _depositDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(double currentBalance) async {
    final amount = CurrencyFormatter.parseRupiah(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal setoran yang valid')),
      );
      return;
    }

    if (currentBalance < amount) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.redMain),
              SizedBox(width: 8),
              Text('Saldo Kas Kurang'),
            ],
          ),
          content: Text(
            'Saldo kas Anda saat ini (${CurrencyFormatter.formatRupiah(currentBalance)}) tidak mencukupi untuk setor tabungan ${CurrencyFormatter.formatRupiah(amount)}.\n\nSilakan catat pemasukan terlebih dahulu.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
          ],
        ),
      );
      return;
    }

    final deposit = SavingDepositModel(
      savingId: widget.saving.id!,
      depositDate: _depositDate,
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(financialControllerProvider.notifier).addSavingDeposit(deposit);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setoran tabungan ${CurrencyFormatter.formatRupiah(amount)} berhasil (Saldo Kas berkurang)!'),
          backgroundColor: AppTheme.bluePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currentBalance = summaryAsync.valueOrNull?.netBalance ?? 0.0;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
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
            bottom: bottomInset + bottomSafe + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                
                Text(
                  'SETOR DANA TABUNGAN',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${widget.saving.savingName} • Target: ${widget.saving.formattedTarget}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Cash Balance Indicator Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: currentBalance > 0 ? AppTheme.borderLight : AppTheme.redMain,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentBalance > 0 ? Icons.account_balance_wallet_rounded : Icons.error_outline_rounded,
                        color: currentBalance > 0 ? AppTheme.greenMain : AppTheme.redMain,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Kas Anda: ${CurrencyFormatter.formatRupiah(currentBalance)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: currentBalance > 0 ? AppTheme.textDark : AppTheme.redMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Setoran akan otomatis memotong Saldo Kas Anda',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Symmetrical Luxury Nominal Box with "Rp"
                Text('NOMINAL SETORAN (RP)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.bluePrimary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          autofocus: true,
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: AppTheme.textLight),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _noteController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Keterangan setoran (misal: Sisa gaji, bonus)...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => _submit(currentBalance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Konfirmasi Setoran Tabungan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
