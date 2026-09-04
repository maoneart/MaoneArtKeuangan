import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt_model.dart';
import '../providers/financial_provider.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'date_picker_modal.dart';

class AddDebtModal extends ConsumerStatefulWidget {
  final String initialType;

  const AddDebtModal({super.key, this.initialType = 'hutang'});

  static Future<void> show(BuildContext context, {String type = 'hutang'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
  final TextEditingController _tenorController = TextEditingController(text: '12');
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Leasing / Kendaraan';
  DateTime _borrowDate = DateTime.now();
  DateTime? _dueDate;
  bool _isInstallmentMode = true;
  int _dueDay = 15;

  final categoriesHutang = [
    'Leasing / Kendaraan',
    'Pinjaman Bank',
    'Kartu Kredit',
    'Pinjaman Online',
    'Perorangan / Teman',
  ];

  final List<int> quickTenors = [6, 12, 24, 33, 36, 48];

  int get _parsedTenor => int.tryParse(_tenorController.text.trim()) ?? 0;
  double get _parsedAmount => CurrencyFormatter.parseRupiah(_amountController.text);
  double get _calculatedInstallment => (_parsedTenor > 0 && _parsedAmount > 0) ? (_parsedAmount / _parsedTenor) : 0.0;

  DateTime get _calculatedMaturityDate {
    final tenor = _parsedTenor > 0 ? _parsedTenor : 1;
    var year = _borrowDate.year;
    var month = _borrowDate.month + tenor;
    while (month > 12) {
      year += 1;
      month -= 12;
    }
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = _dueDay.clamp(1, maxDay);
    return DateTime(year, month, day);
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_type == 'piutang') {
      _selectedCategory = 'Perorangan / Teman';
    }
    _amountController.addListener(() => setState(() {}));
    _tenorController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _tenorController.dispose();
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

    DateTime? finalDueDate;
    int tenorMonths = 0;
    int dueDay = 0;
    double monthlyInstallment = 0.0;

    if (_isInstallmentMode && _parsedTenor > 0) {
      tenorMonths = _parsedTenor;
      dueDay = _dueDay;
      monthlyInstallment = _calculatedInstallment;
      finalDueDate = _calculatedMaturityDate;
    } else {
      finalDueDate = _dueDate;
    }

    final debt = DebtModel(
      debtorName: name,
      type: _type,
      categoryDebt: _selectedCategory,
      totalAmount: amount,
      remainingAmount: amount,
      borrowDate: _borrowDate,
      dueDate: finalDueDate,
      tenorMonths: tenorMonths,
      dueDay: dueDay,
      monthlyInstallment: monthlyInstallment,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ref.read(financialControllerProvider.notifier).addDebt(debt);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type == 'hutang' ? 'Hutang' : 'Piutang'} berhasil dicatat!'),
          backgroundColor: _type == 'hutang' ? AppTheme.redMain : AppTheme.bluePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'TAMBAH CATATAN ${_type.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Tab Pilihan: Hutang Saya vs Piutang Orang
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
                          onTap: () => setState(() => _type = 'hutang'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type == 'hutang' ? AppTheme.redMain : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Hutang Saya (Wajib Bayar)',
                              style: GoogleFonts.plusJakartaSans(
                                color: _type == 'hutang' ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
                              color: _type == 'piutang' ? AppTheme.greenMain : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Piutang (Harus Ditagih)',
                              style: GoogleFonts.plusJakartaSans(
                                color: _type == 'piutang' ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nama Orang / Pihak
                Text(
                  _type == 'hutang' ? 'PEMBERI PINJAMAN / NAMA PIHAK' : 'NAMA PEMINJAM / PENGHUTANG',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  autofocus: false,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Leasing Honda, Budi, Bank BCA...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                  ),
                ),
                const SizedBox(height: 14),

                // Kategori Hutang / Pinjaman
                Text(
                  'KATEGORI PINJAMAN',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                      items: categoriesHutang.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Total Nominal
                Text(
                  'TOTAL NOMINAL PINJAMAN',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _type == 'hutang' ? AppTheme.redMain.withValues(alpha: 0.5) : AppTheme.greenMain.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
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
                          style: GoogleFonts.plusJakartaSans(
                            color: _type == 'hutang' ? AppTheme.redMain : AppTheme.greenMain,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
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
                const SizedBox(height: 16),

                // Skema Pembayaran Switcher (Cicilan Rutin Tenor vs Satu Kali Pelunasan)
                Text(
                  'SKEMA PEMBAYARAN & JATUH TEMPO',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isInstallmentMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isInstallmentMode ? AppTheme.bluePrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calculate_rounded, size: 14, color: _isInstallmentMode ? Colors.white : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Cicilan & Tenor Bulanan',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _isInstallmentMode ? Colors.white : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isInstallmentMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isInstallmentMode ? AppTheme.bluePrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded, size: 14, color: !_isInstallmentMode ? Colors.white : AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Batas Tanggal Bebas',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: !_isInstallmentMode ? Colors.white : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
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
                const SizedBox(height: 14),

                // Form Sesuai Skema
                if (_isInstallmentMode) ...[
                  // Tanggal Mulai Pinjam
                  InkWell(
                    onTap: () async {
                      final picked = await DatePickerModal.show(
                        context,
                        initialDate: _borrowDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _borrowDate = picked);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppTheme.bluePrimary, size: 18),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal Mulai Pinjam / Akad', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              const SizedBox(height: 2),
                              Text(AppDateFormatter.formatFull(_borrowDate), style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tenor Bulan & Jatuh Tempo Hari
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tenor (Bulan)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LAMA TENOR (BULAN)', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _tenorController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: InputDecoration(
                                suffixText: 'Bulan',
                                suffixStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Jatuh Tempo Tiap Tanggal
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('JATUH TEMPO RUTIN', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _dueDay,
                                  isExpanded: true,
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.bold),
                                  items: List.generate(31, (i) => i + 1).map((d) {
                                    return DropdownMenuItem<int>(
                                      value: d,
                                      child: Text('Tiap Tgl $d'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _dueDay = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Tenor Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickTenors.map((t) {
                        final isSelected = _parsedTenor == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('$t bln', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textDark)),
                            backgroundColor: isSelected ? AppTheme.bluePrimary : const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide.none,
                            onPressed: () {
                              _tenorController.text = t.toString();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live Simulation Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'KALKULASI SIMULASI CICILAN',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF065F46),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimasi Cicilan / Bulan', style: TextStyle(color: const Color(0xFF047857), fontSize: 10.5, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.formatRupiah(_calculatedInstallment),
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFA7F3D0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimasi Lunas (Bulan ke-$_parsedTenor)', style: TextStyle(color: const Color(0xFF047857), fontSize: 10.5, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppDateFormatter.formatMonthYear(_calculatedMaturityDate),
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📅 Jadwal jatuh tempo tagihan: Tiap tanggal $_dueDay setiap bulan sampai lunas.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF047857), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Mode Bebas: Tanggal Pinjam & Tanggal Jatuh Tempo
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await DatePickerModal.show(context, initialDate: _borrowDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                            if (picked != null) setState(() => _borrowDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tgl Pinjam', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(AppDateFormatter.formatShort(_borrowDate), style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await DatePickerModal.show(context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2035));
                            if (picked != null) setState(() => _dueDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Jatuh Tempo', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  _dueDate != null ? AppDateFormatter.formatShort(_dueDate!) : 'Pilih Tenggat',
                                  style: GoogleFonts.plusJakartaSans(color: _dueDate != null ? AppTheme.bluePrimary : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Catatan
                TextField(
                  controller: _noteController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Keterangan tambahan (misal: Cicilan ke dealer, kontak dll)...',
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'hutang' ? AppTheme.redMain : AppTheme.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Simpan Data ${_type == 'hutang' ? 'Hutang' : 'Piutang'}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
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
      useSafeArea: true,
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
    _amountController.text = CurrencyFormatter.formatThousands(widget.debt.remainingAmount);
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

    if (widget.debt.isDebt) {
      if (currentBalance < amount) {
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
              'Saldo kas Anda saat ini (${CurrencyFormatter.formatRupiah(currentBalance)}) tidak mencukupi untuk melunasi/mencicil hutang sebesar ${CurrencyFormatter.formatRupiah(amount)}.\n\nSilakan catat pemasukan terlebih dahulu.',
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
          backgroundColor: widget.debt.isDebt ? AppTheme.greenMain : AppTheme.bluePrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currentBalance = summaryAsync.valueOrNull?.netBalance ?? 0.0;
    final isDebt = widget.debt.isDebt;
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
                  isDebt ? 'BAYAR / CICIL HUTANG SAYA' : 'TERIMA PEMBAYARAN PIUTANG',
                  style: GoogleFonts.plusJakartaSans(color: isDebt ? AppTheme.redMain : AppTheme.bluePrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${widget.debt.debtorName} • Sisa: ${widget.debt.formattedRemaining}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDebt
                          ? (currentBalance > 0 ? AppTheme.borderLight : AppTheme.redMain)
                          : AppTheme.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDebt
                            ? (currentBalance > 0 ? Icons.account_balance_wallet_rounded : Icons.error_outline_rounded)
                            : Icons.savings_rounded,
                        color: isDebt ? (currentBalance > 0 ? AppTheme.greenMain : AppTheme.redMain) : AppTheme.bluePrimary,
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
                                color: isDebt ? (currentBalance > 0 ? AppTheme.textDark : AppTheme.redMain) : AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              isDebt
                                  ? 'Pembayaran akan otomatis memotong Saldo Kas Anda'
                                  : 'Uang yang diterima akan otomatis menambah Saldo Kas Anda',
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
                Text('NOMINAL PEMBAYARAN', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDebt ? AppTheme.redMain.withValues(alpha: 0.5) : AppTheme.bluePrimary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
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
                          style: GoogleFonts.plusJakartaSans(
                            color: isDebt ? AppTheme.redMain : AppTheme.bluePrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
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

                // Tanggal Pembayaran / Cicilan
                Text(
                  isDebt ? 'TANGGAL PEMBAYARAN HUTANG' : 'TANGGAL PENERIMAAN PIUTANG',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await DatePickerModal.show(
                      context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _paymentDate = picked);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: isDebt ? AppTheme.redMain : AppTheme.bluePrimary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppDateFormatter.formatFull(_paymentDate),
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _noteController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isDebt ? 'Keterangan (misal: Cicilan ke-1)...' : 'Keterangan (misal: Transfer BCA)...',
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
                    backgroundColor: isDebt ? AppTheme.redMain : AppTheme.bluePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    isDebt ? 'Konfirmasi Bayar Hutang' : 'Konfirmasi Terima Piutang',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
