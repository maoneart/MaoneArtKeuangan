import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

enum _PickerMode { day, month, year }

class DatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const DatePickerModal({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showGeneralDialog<DateTime>(
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
            child: DatePickerModal(
              initialDate: initialDate,
              firstDate: firstDate ?? DateTime(2020, 1, 1),
              lastDate: lastDate ?? DateTime(2035, 12, 31),
            ),
          ),
        );
      },
    );
  }

  @override
  State<DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<DatePickerModal> {
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;
  _PickerMode _mode = _PickerMode.day;

  final List<String> _weekdays = const ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];

  final List<Map<String, dynamic>> _months = const [
    {'code': 1, 'name': 'Januari', 'short': 'Jan'},
    {'code': 2, 'name': 'Februari', 'short': 'Feb'},
    {'code': 3, 'name': 'Maret', 'short': 'Mar'},
    {'code': 4, 'name': 'April', 'short': 'Apr'},
    {'code': 5, 'name': 'Mei', 'short': 'Mei'},
    {'code': 6, 'name': 'Juni', 'short': 'Jun'},
    {'code': 7, 'name': 'Juli', 'short': 'Jul'},
    {'code': 8, 'name': 'Agustus', 'short': 'Agu'},
    {'code': 9, 'name': 'September', 'short': 'Sep'},
    {'code': 10, 'name': 'Oktober', 'short': 'Okt'},
    {'code': 11, 'name': 'November', 'short': 'Nov'},
    {'code': 12, 'name': 'Desember', 'short': 'Des'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewYear = widget.initialDate.year;
    _viewMonth = widget.initialDate.month;
  }

  void _previousMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return _months[month - 1]['name'] as String;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
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
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    if (_mode == _PickerMode.day) _buildDayPicker(),
                    if (_mode == _PickerMode.month) _buildMonthPicker(),
                    if (_mode == _PickerMode.year) _buildYearPicker(),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header with Mode Switchers & Navigation
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppTheme.bluePrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mode == _PickerMode.year
                        ? 'Pilih Tahun'
                        : (_mode == _PickerMode.month ? 'Pilih Bulan' : 'Pilih Tanggal'),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    AppDateFormatter.formatShort(_selectedDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppTheme.bluePrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Navigation / Switchers
          if (_mode == _PickerMode.day)
            Row(
              children: [
                // Month Selector Chip
                InkWell(
                  onTap: () => setState(() => _mode = _PickerMode.month),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _months[_viewMonth - 1]['short'],
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppTheme.bluePrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.bluePrimary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Year Selector Chip
                InkWell(
                  onTap: () => setState(() => _mode = _PickerMode.year),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_viewYear',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppTheme.bluePrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.bluePrimary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Month Navigation Chevrons
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: _previousMonth,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: _nextMonth,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                ),
              ],
            )
          else
            // Back to Day Picker Button
            TextButton.icon(
              onPressed: () => setState(() => _mode = _PickerMode.day),
              icon: const Icon(Icons.calendar_month_rounded, size: 15),
              label: Text(
                'Kalender',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.bluePrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: AppTheme.blueLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // 2. Day / Calendar View
  Widget _buildDayPicker() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_viewYear, _viewMonth, 1);
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    // Sunday is index 0
    final leadingSpaces = firstDayOfMonth.weekday % 7;
    final totalGridItems = leadingSpaces + daysInMonth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Month Year Title Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getMonthName(_viewMonth)} $_viewYear',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Pilih tanggal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekdays.map((day) {
              final isWeekend = day == 'MIN' || day == 'SAB';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isWeekend ? const Color(0xFFEF4444) : AppTheme.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Day Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, index) {
              if (index < leadingSpaces) {
                return const SizedBox.shrink();
              }

              final day = index - leadingSpaces + 1;
              final cellDate = DateTime(_viewYear, _viewMonth, day);
              final isSelected = _isSameDay(cellDate, _selectedDate);
              final isToday = _isSameDay(cellDate, now);
              final isDisabled = cellDate.isBefore(widget.firstDate) || cellDate.isAfter(widget.lastDate);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = cellDate;
                          });
                          Navigator.of(context).pop(cellDate);
                        },
                  borderRadius: BorderRadius.circular(10),
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
                          : (isToday ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isToday ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                        width: isToday ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0047CC).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$day',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDisabled
                            ? const Color(0xFFCBD5E1)
                            : (isSelected
                                ? Colors.white
                                : (isToday ? const Color(0xFF1D4ED8) : const Color(0xFF334155))),
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Month Selection View (Identical to MonthPickerModal)
  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // Year Switcher inside Month Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: () => setState(() => _viewYear--),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  'Tahun $_viewYear',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.bluePrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: () => setState(() => _viewYear++),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // 12 Months Grid (4 Rows x 3 Columns)
          GridView.builder(
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
              final monthCode = m['code'] as int;
              final isSelected = _viewMonth == monthCode;
              final now = DateTime.now();
              final isThisMonth = _viewYear == now.year && monthCode == now.month;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _viewMonth = monthCode;
                      _mode = _PickerMode.day;
                    });
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
                      m['short'],
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
        ],
      ),
    );
  }

  // 4. Year Selection View
  Widget _buildYearPicker() {
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;
    final yearList = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Pilih Tahun Transaksi ($startYear - $endYear)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: yearList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (ctx, i) {
                final year = yearList[i];
                final isSelected = _viewYear == year;
                final isThisYear = year == DateTime.now().year;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _viewYear = year;
                        _mode = _PickerMode.month;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
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
                            : (isThisYear ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isThisYear ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                          width: isThisYear ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0047CC).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$year',
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected
                              ? Colors.white
                              : (isThisYear ? const Color(0xFF1D4ED8) : const Color(0xFF334155)),
                          fontWeight: isSelected || isThisYear ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 5. Quick Action Symmetrical 2-Column Buttons
  Widget _buildBottomActions() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        children: [
          // Button 1: Hari Ini
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(now);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.bluePrimary,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.today_rounded, size: 16),
              label: Text(
                'Hari Ini',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Button 2: Kemarin
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(yesterday);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.history_rounded, size: 16),
              label: Text(
                'Kemarin',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
