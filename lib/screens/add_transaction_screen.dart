import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/maoneart_modal.dart';
import 'category_management_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String initialType;
  final CategoryModel? preSelectedCategory;
  final int? preSelectedCategoryId;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'pengeluaran',
    this.preSelectedCategory,
    this.preSelectedCategoryId,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _type = widget.preSelectedCategory?.type ?? widget.initialType;
    _selectedCategoryId = widget.preSelectedCategory?.id ?? widget.preSelectedCategoryId;
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
        const SnackBar(
          content: Text('Masukkan nominal transaksi yang valid'),
          backgroundColor: AppTheme.redMain,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori transaksi terlebih dahulu'),
          backgroundColor: AppTheme.bluePrimary,
        ),
      );
      return;
    }

    // Validasi Saldo Kas jika Pengeluaran
    if (_type == 'pengeluaran') {
      final summary = await ref.read(financialSummaryProvider.future);
      if (summary.netBalance < amount) {
        if (mounted) {
          MaoneArtModal.showAlertModal(
            context: context,
            title: 'Saldo Kas Tidak Cukup',
            message: 'Saldo kas Anda saat ini (${CurrencyFormatter.formatRupiah(summary.netBalance)}) tidak mencukupi untuk pengeluaran sebesar ${CurrencyFormatter.formatRupiah(amount)}.\n\nSilakan top up kas atau sesuaikan nominal pengeluaran.',
            accentColor: AppTheme.redMain,
            icon: Icons.warning_amber_rounded,
            buttonText: 'Mengerti',
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
          content: Text('${_type == 'pemasukan' ? 'Pemasukan (Top Up)' : 'Pengeluaran'} senilai ${CurrencyFormatter.formatRupiah(amount)} berhasil disimpan! ✨'),
          backgroundColor: _type == 'pemasukan' ? AppTheme.greenMain : AppTheme.redMain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bottomPadding = MediaQuery.of(context).padding.bottom + (isLandscape ? 30 : 50);

    final isIncome = _type == 'pemasukan';
    final pageTitle = isIncome ? 'Top Up Saldo Kas' : 'Catat Pengeluaran';
    final primaryColor = isIncome ? AppTheme.greenMain : AppTheme.redMain;

    return Scaffold(
      backgroundColor: AppTheme.bgApp,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
        actions: [
          IconButton(
            tooltip: 'Kelola Kategori',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.bluePrimary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== 1. TAB SWITCHER (Pengeluaran vs Pemasukan) ====================
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome ? AppTheme.redMain : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isIncome
                                ? [
                                    BoxShadow(
                                      color: AppTheme.redMain.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: 16, color: !isIncome ? Colors.white : AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Pengeluaran (Bayar)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: !isIncome ? Colors.white : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'pemasukan';
                          _selectedCategoryId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome ? AppTheme.greenMain : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isIncome
                                ? [
                                    BoxShadow(
                                      color: AppTheme.greenMain.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 16, color: isIncome ? Colors.white : AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Pemasukan (Top Up)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: isIncome ? Colors.white : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==================== 2. NOMINAL INPUT CARD ====================
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMINAL TRANSAKSI',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Rp',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textDark,
                              fontSize: 24,
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
                              style: GoogleFonts.plusJakartaSans(
                                color: primaryColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600),
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
              const SizedBox(height: 16),

              // ==================== 3. KATEGORI TRANSAKSI ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PILIH KATEGORI (${isIncome ? 'PEMASUKAN' : 'PENGELUARAN'})',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14, color: AppTheme.bluePrimary),
                    label: Text(
                      'Kelola',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.bluePrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              categoriesAsync.when(
                data: (cats) {
                  final filtered = cats.where((c) => c.type == _type).toList();
                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada kategori ${_type == 'pemasukan' ? 'pemasukan' : 'pengeluaran'}',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    );
                  }

                  final crossCount = isLandscape ? 6 : 3;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: isLandscape ? 2.5 : 2.2,
                    ),
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      final isSelected = _selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color.withValues(alpha: 0.12) : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? cat.color : AppTheme.borderLight,
                              width: isSelected ? 1.8 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cat.color.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cat.iconData, color: cat.color, size: 15),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? cat.color : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (_, __) => const Text('Gagal memuat kategori'),
              ),
              const SizedBox(height: 18),

              // ==================== 4. TANGGAL & KETERANGAN ====================
              Text(
                'TANGGAL & KETERANGAN',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date Selector
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppTheme.bluePrimary, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  AppDateFormatter.formatFull(_selectedDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes Input
                    TextField(
                      controller: _noteController,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Keterangan / Catatan (opsional)',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.textMuted, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==================== 5. TOMBOL AKSI SIMETRIS ====================
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textDark,
                          side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          isIncome ? 'Simpan Top Up' : 'Simpan Bayar',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
