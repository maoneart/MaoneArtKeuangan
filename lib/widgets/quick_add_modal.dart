import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class QuickAddModal extends ConsumerStatefulWidget {
  final String initialType;

  const QuickAddModal({super.key, this.initialType = 'pengeluaran'});

  static Future<void> show(BuildContext context, {String type = 'pengeluaran'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddModal(initialType: type),
    );
  }

  @override
  ConsumerState<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends ConsumerState<QuickAddModal> {
  late String _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

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
        const SnackBar(content: Text('Masukkan nominal transaksi yang valid')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori transaksi terlebih dahulu')),
      );
      return;
    }

    // Validasi Saldo Kas jika Pengeluaran
    if (_type == 'pengeluaran') {
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
                'Saldo kas Anda (${CurrencyFormatter.formatRupiah(summary.netBalance)}) tidak mencukupi untuk pengeluaran sebesar ${CurrencyFormatter.formatRupiah(amount)}.',
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
    }

    final tx = TransactionModel(
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(financialControllerProvider.notifier).addTransaction(tx);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'} berhasil dicatat!'),
          backgroundColor: _type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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

            // Tab Pilihan: Pengeluaran vs Pemasukan
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = 'pengeluaran';
                        _selectedCategoryId = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'pengeluaran' ? AppTheme.redMain : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pengeluaran (-)',
                          style: GoogleFonts.plusJakartaSans(
                            color: _type == 'pengeluaran' ? Colors.white : AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = 'pemasukan';
                        _selectedCategoryId = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'pemasukan' ? AppTheme.greenMain : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pemasukan (+)',
                          style: GoogleFonts.plusJakartaSans(
                            color: _type == 'pemasukan' ? Colors.white : AppTheme.textMuted,
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
            const SizedBox(height: 18),

            // Nominal Input
            Text(
              'NOMINAL TRANSAKSI (RP)',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                color: _type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0',
                hintStyle: const TextStyle(color: AppTheme.textLight),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Kategori
            Text(
              'PILIH KATEGORI',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            categoriesAsync.when(
              data: (cats) {
                final filtered = cats.where((c) => c.type == _type).toList();
                if (filtered.isEmpty) {
                  return Text('Belum ada kategori untuk $_type', style: const TextStyle(color: AppTheme.textMuted));
                }

                return SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      final isSelected = _selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? (_type == 'pemasukan' ? AppTheme.greenSoft : AppTheme.redSoft) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? (_type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(cat.iconData, color: isSelected ? (_type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain) : AppTheme.textMuted, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? AppTheme.textDark : AppTheme.textBody,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Gagal memuat kategori'),
            ),
            const SizedBox(height: 14),

            // Tanggal Transaksi & Keterangan
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppTheme.bluePrimary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            AppDateFormatter.formatShort(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Catatan
            TextField(
              controller: _noteController,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Keterangan/Catatan tambahan (opsional)...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Simpan ${_type == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
