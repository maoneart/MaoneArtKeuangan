import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class AddDebtModal extends ConsumerStatefulWidget {
  final String initialType;

  const AddDebtModal({super.key, this.initialType = 'hutang'});

  static Future<void> show(BuildContext context, {String type = 'hutang'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDebtModal(initialType: type),
    );
  }

  @override
  ConsumerState<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends ConsumerState<AddDebtModal> {
  late String _type;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(text: 'Perorangan / Teman');
  final TextEditingController _noteController = TextEditingController();
  DateTime _borrowDate = DateTime.now();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final amount = CurrencyFormatter.parseRupiah(_amountController.text);

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama orang/pihak dan nominal yang valid')),
      );
      return;
    }

    final debt = DebtModel(
      debtorName: name,
      type: _type,
      categoryDebt: _categoryController.text.trim(),
      totalAmount: amount,
      remainingAmount: amount,
      borrowDate: _borrowDate,
      dueDate: _dueDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(financialControllerProvider.notifier).addDebt(debt);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type == 'hutang' ? 'Hutang' : 'Piutang'} berhasil dicatat!'),
          backgroundColor: _type == 'hutang' ? AppTheme.accentRose : AppTheme.accentCyan,
        ),
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
                decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Pilihan: Hutang Saya vs Piutang Orang
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'hutang'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'hutang' ? AppTheme.accentRose : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Hutang Saya (Wajib Bayar)',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'piutang'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'piutang' ? AppTheme.accentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Piutang (Harus Ditagih)',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Nama Orang / Pihak
            Text(
              _type == 'hutang' ? 'PEMBERI PINJAMAN / NAMA TEMAN' : 'NAMA PEMINJAM / PENGHUTANG',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Contoh: Budi, Bank BCA, ShopeePayLater...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Nominal Hutang/Piutang
            Text('TOTAL NOMINAL (RP)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: _type == 'hutang' ? AppTheme.accentRose : AppTheme.accentCyan, fontSize: 24, fontWeight: FontWeight.w900),
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

            // Tanggal Pinjam & Jatuh Tempo
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _borrowDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (picked != null) setState(() => _borrowDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tgl Pinjam', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(AppDateFormatter.formatShort(_borrowDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2035));
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jatuh Tempo', style: TextStyle(color: Colors.white60, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(_dueDate != null ? AppDateFormatter.formatShort(_dueDate!) : 'Pilih Tenggat', style: TextStyle(color: _dueDate != null ? AppTheme.accentAmber : Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Catatan
            TextField(
              controller: _noteController,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Keterangan tambahan...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'hutang' ? AppTheme.accentRose : AppTheme.accentCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Simpan Data ${_type == 'hutang' ? 'Hutang' : 'Piutang'}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class PayDebtModal extends ConsumerStatefulWidget {
  final DebtModel debt;

  const PayDebtModal({super.key, required this.debt});

  static Future<void> show(BuildContext context, DebtModel debt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayDebtModal(debt: debt),
    );
  }

  @override
  ConsumerState<PayDebtModal> createState() => _PayDebtModalState();
}

class _PayDebtModalState extends ConsumerState<PayDebtModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.debt.remainingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(double currentBalance) async {
    final amount = CurrencyFormatter.parseRupiah(_amountController.text);
    if (amount <= 0 || amount > widget.debt.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nominal bayar harus antara Rp 1 s/d ${widget.debt.formattedRemaining}')),
      );
      return;
    }

    // Validasi Saldo Kas jika ini adalah Bayar Hutang (Pengeluaran)
    if (widget.debt.isDebt) {
      if (currentBalance < amount) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.bgCard,
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.accentRose),
                SizedBox(width: 8),
                Text('Saldo Tidak Cukup'),
              ],
            ),
            content: Text(
              'Saldo kas Anda saat ini (${CurrencyFormatter.formatRupiah(currentBalance)}) tidak mencukupi untuk melunasi/mencicil hutang sebesar ${CurrencyFormatter.formatRupiah(amount)}.\n\nSilakan catat pemasukan terlebih dahulu.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup', style: TextStyle(color: Colors.white))),
            ],
          ),
        );
        return;
      }
    }

    await ref.read(financialControllerProvider.notifier).payDebt(
      widget.debt.id!,
      amount,
      _paymentDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.debt.isDebt
                ? 'Hutang berhasil dibayar ${CurrencyFormatter.formatRupiah(amount)} (Saldo Kas berkurang)'
                : 'Piutang berhasil diterima ${CurrencyFormatter.formatRupiah(amount)} (Saldo Kas bertambah)',
          ),
          backgroundColor: widget.debt.isDebt ? AppTheme.accentEmerald : AppTheme.accentCyan,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currentBalance = summaryAsync.valueOrNull?.netBalance ?? 0.0;
    final isDebt = widget.debt.isDebt;

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
            
            // Header Modal
            Text(
              isDebt ? 'BAYAR / CICIL HUTANG SAYA' : 'TERIMA PEMBAYARAN PIUTANG',
              style: GoogleFonts.outfit(color: isDebt ? AppTheme.accentEmerald : AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${widget.debt.debtorName} • Sisa: ${widget.debt.formattedRemaining}',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Banner Saldo Kas & Dampak Finansial
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDebt
                      ? (currentBalance > 0 ? AppTheme.accentEmerald.withValues(alpha: 0.3) : AppTheme.accentRose)
                      : AppTheme.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDebt
                        ? (currentBalance > 0 ? Icons.account_balance_wallet_rounded : Icons.error_outline_rounded)
                        : Icons.savings_rounded,
                    color: isDebt ? (currentBalance > 0 ? AppTheme.accentEmerald : AppTheme.accentRose) : AppTheme.accentCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Kas Anda: ${CurrencyFormatter.formatRupiah(currentBalance)}',
                          style: GoogleFonts.outfit(
                            color: isDebt ? (currentBalance > 0 ? Colors.white : AppTheme.accentRose) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          isDebt
                              ? 'Pembayaran akan otomatis memotong Saldo Kas Anda'
                              : 'Uang yang diterima akan otomatis menambah Saldo Kas Anda',
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Nominal Bayar
            Text('NOMINAL PEMBAYARAN (RP)', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(color: isDebt ? AppTheme.accentEmerald : AppTheme.accentCyan, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Keterangan / Catatan
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: isDebt ? 'Keterangan (misal: Cicilan ke-1)...' : 'Keterangan (misal: Transfer BCA)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _submit(currentBalance),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDebt ? AppTheme.accentEmerald : AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isDebt ? 'Konfirmasi Bayar Hutang' : 'Konfirmasi Terima Piutang',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
