import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class MonthPickerModal extends StatefulWidget {
  final String currentMonth; // Format 'YYYY-MM' atau 'all'
  final ValueChanged<String> onMonthSelected;

  const MonthPickerModal({
    super.key,
    required this.currentMonth,
    required this.onMonthSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentMonth,
    required ValueChanged<String> onMonthSelected,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: MonthPickerModal(
              currentMonth: currentMonth,
              onMonthSelected: onMonthSelected,
            ),
          ),
        );
      },
    );
  }

  @override
  State<MonthPickerModal> createState() => _MonthPickerModalState();
}

class _MonthPickerModalState extends State<MonthPickerModal> {
  late int _selectedYear;
  late String _activeMonthKey;

  final List<Map<String, String>> _months = const [
    {'code': '01', 'name': 'Januari', 'short': 'Jan'},
    {'code': '02', 'name': 'Februari', 'short': 'Feb'},
    {'code': '03', 'name': 'Maret', 'short': 'Mar'},
    {'code': '04', 'name': 'April', 'short': 'Apr'},
    {'code': '05', 'name': 'Mei', 'short': 'Mei'},
    {'code': '06', 'name': 'Juni', 'short': 'Jun'},
    {'code': '07', 'name': 'Juli', 'short': 'Jul'},
    {'code': '08', 'name': 'Agustus', 'short': 'Agu'},
    {'code': '09', 'name': 'September', 'short': 'Sep'},
    {'code': '10', 'name': 'Oktober', 'short': 'Okt'},
    {'code': '11', 'name': 'November', 'short': 'Nov'},
    {'code': '12', 'name': 'Desember', 'short': 'Des'},
  ];

  @override
  void initState() {
    super.initState();
    _activeMonthKey = widget.currentMonth;
    if (_activeMonthKey.contains('-')) {
      final parts = _activeMonthKey.split('-');
      _selectedYear = int.tryParse(parts[0]) ?? DateTime.now().year;
    } else {
      _selectedYear = DateTime.now().year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0047CC).withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header with Year Controls
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.blueLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.bluePrimary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pilih Periode',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        // Year Switcher
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedYear--;
                                  });
                                },
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                splashRadius: 16,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$_selectedYear',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.bluePrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedYear++;
                                  });
                                },
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                splashRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. 12 Month Grid (4 Rows x 3 Columns)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _months.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.1,
                      ),
                      itemBuilder: (ctx, i) {
                        final m = _months[i];
                        final monthKey = '$_selectedYear-${m['code']}';
                        final isSelected = monthKey == _activeMonthKey;
                        final isThisMonth = monthKey == nowKey;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              widget.onMonthSelected(monthKey);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF002680), Color(0xFF0047CC)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isThisMonth ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isThisMonth ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                                  width: isThisMonth ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0047CC).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                m['short']!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? Colors.white
                                      : (isThisMonth ? const Color(0xFF1D4ED8) : const Color(0xFF334155)),
                                  fontWeight: isSelected || isThisMonth ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Quick Action Symmetrical 2-Column Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Row(
                      children: [
                        // Button 1: Bulan Sekarang
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onMonthSelected(nowKey);
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.bluePrimary,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.today_rounded, size: 16),
                            label: Text(
                              'Bulan Ini',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 2: Semua Periode
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.onMonthSelected('all');
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _activeMonthKey == 'all' ? const Color(0xFF002680) : const Color(0xFF0047CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.all_inclusive_rounded, size: 16),
                            label: Text(
                              'Semua',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
