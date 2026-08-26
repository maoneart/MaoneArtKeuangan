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

  void _submit() async {
    final name = _nameController.text.trim();
    final target = CurrencyFormatter.parseRupiah(_targetController.text);
    final initialDeposit = CurrencyFormatter.parseRupiah(_initialDepositController.text);

    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama impian dan target nominal yang valid')),
      );
      return;
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
        const SnackBar(
          content: Text('Target impian berhasil dibuat!'),
          backgroundColor: AppTheme.bluePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),

            // Nama Target Impian
            Text('NAMA TARGET IMPIAN', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 15),
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

            // Target Nominal
            Text('TARGET JUMLAH DANA (RP)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 24, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 22, fontWeight: FontWeight.bold),
                hintText: '0',
                hintStyle: const TextStyle(color: AppTheme.textLight),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
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
                      TextField(
                        controller: _initialDepositController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 14),
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            _dueDate != null ? AppDateFormatter.formatShort(_dueDate!) : 'Pilih Tanggal',
                            style: GoogleFonts.plusJakartaSans(
                              color: _dueDate != null ? AppTheme.bluePrimary : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bluePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Simpan Target Impian', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
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

  void _submit() async {
    final amount = CurrencyFormatter.parseRupiah(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal setoran yang valid')),
      );
      return;
    }

    final summary = await ref.read(financialSummaryProvider.future);
    if (summary.netBalance < amount) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.redMain),
                SizedBox(width: 8),
                Text('Saldo Tidak Cukup'),
              ],
            ),
            content: Text(
              'Saldo kas Anda (${CurrencyFormatter.formatRupiah(summary.netBalance)}) tidak mencukupi untuk setor tabungan sebesar ${CurrencyFormatter.formatRupiah(amount)}.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
            ],
          ),
        );
      }
      return;
    }

    await ref.read(financialControllerProvider.notifier).depositSaving(
      widget.saving.id!,
      amount,
      _depositDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setoran ${CurrencyFormatter.formatRupiah(amount)} berhasil! (Saldo Kas terpotong)'),
          backgroundColor: AppTheme.greenMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
              'SETOR DANA TABUNGAN',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${widget.saving.savingName} • Target: ${widget.saving.formattedTarget}',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Input Nominal Setoran
            Text('NOMINAL SETORAN (RP)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.bluePrimary, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 22, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
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
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bluePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Konfirmasi Setor Dana', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
