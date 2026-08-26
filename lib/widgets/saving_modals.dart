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
        const SnackBar(content: Text('Target impian tabungan baru berhasil dibuat!'), backgroundColor: AppTheme.accentCyan),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text('BUAT TARGET TABUNGAN / IMPIAN', style: GoogleFonts.outfit(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // Nama Target Impian
            Text('NAMA IMPIAN / TUJUAN', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Contoh: Beli iPhone, Liburan ke Bali, DP Rumah...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Target Nominal
            Text('TARGET DANA (RP)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: AppTheme.accentCyan, fontSize: 24, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Setoran Awal (Opsional)
            Text('SETORAN AWAL (OPSIONAL)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _initialDepositController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: Colors.white70),
                hintText: '0 (Bisa disetor nanti)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Tenggat Waktu Target
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 90)), firstDate: DateTime.now(), lastDate: DateTime(2040));
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Selesai', style: TextStyle(color: Colors.white60, fontSize: 10)),
                        Text(_dueDate != null ? AppDateFormatter.formatFull(_dueDate!) : 'Pilih Tenggat Waktu (Opsional)', style: TextStyle(color: _dueDate != null ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Buat Target Impian', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal setoran yang valid')));
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
        const SnackBar(content: Text('Setoran tabungan berhasil disimpan!'), backgroundColor: AppTheme.accentCyan),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text('SETOR DANA TABUNGAN', style: GoogleFonts.outfit(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.saving.name} • Sisa Target: ${widget.saving.formattedRemaining}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(color: AppTheme.accentCyan, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Keterangan (misal: Sisa gaji bulanan)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Simpan Setoran Tabungan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
