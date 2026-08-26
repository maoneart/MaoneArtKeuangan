import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../providers/financial_provider.dart';
import '../services/pdf_export_service.dart';
import '../services/csv_export_service.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/glass_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedPieIndex = -1;
  int _touchedBarGroupIndex = -1;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentMonth = ref.watch(selectedMonthProvider);

    final parts = currentMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final periodLabel = AppDateFormatter.formatMonthYear(monthDate);

    final bottomPadding = MediaQuery.of(context).padding.bottom + 40;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Laporan & Statistik', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // Filter Periode Bulan
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: monthDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                final newMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
                ref.read(selectedMonthProvider.notifier).state = newMonth;
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.accentEmerald, size: 16),
            label: Text(periodLabel, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Ekspor Dokumen Actions (PDF & CSV / Excel)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final summary = await ref.read(financialSummaryProvider.future);
                        final txs = await ref.read(transactionsProvider.future);
                        if (txs.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data transaksi untuk diekspor')));
                          }
                          return;
                        }
                        final path = await PdfExportService.generateFinancialReport(
                          periodTitle: periodLabel,
                          summary: summary,
                          transactions: txs,
                        );
                        await PdfExportService.sharePdf(path, subject: 'Laporan Keuangan $periodLabel');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentEmerald,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.black),
                      label: Text('Ekspor PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final txs = await ref.read(transactionsProvider.future);
                        if (txs.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data transaksi untuk diekspor')));
                          }
                          return;
                        }
                        final path = await CsvExportService.exportTransactionsToCsv(txs);
                        await CsvExportService.shareCsv(path);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.table_chart_rounded, size: 18, color: AppTheme.accentCyan),
                      label: Text('Ekspor Excel/CSV', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Ringkasan Finansial Periode
              summaryAsync.when(
                data: (summary) => GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ringkasan Arus Kas $periodLabel', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(color: Colors.white12, height: 20),
                      _buildSummaryRow('Total Pemasukan', summary.formattedIncome, color: AppTheme.accentEmerald),
                      _buildSummaryRow('Total Pengeluaran', summary.formattedExpense, color: AppTheme.accentRose),
                      const Divider(color: Colors.white24, height: 20),
                      _buildSummaryRow('Arus Kas Bersih (Surplus/Defisit)', summary.formattedBalance, color: summary.netBalance >= 0 ? AppTheme.accentCyan : AppTheme.accentRose, isBold: true),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),

              // 3. GRAFIK BATANG (Bar Chart) Arus Kas Mingguan
              transactionsAsync.when(
                data: (txs) => _buildBarChartCard(txs, periodLabel),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),

              // 4. GRAFIK LINGKARAN (Pie Chart) Pengeluaran per Kategori
              transactionsAsync.when(
                data: (txs) => _buildPieChartCard(txs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== GRAFIK BATANG (BAR CHART) ====================
  Widget _buildBarChartCard(List<TransactionModel> txs, String periodLabel) {
    if (txs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 44),
              const SizedBox(height: 8),
              Text('Belum ada data untuk grafik batang mingguan', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Hitung Pemasukan & Pengeluaran per Minggu (W1: 1-7, W2: 8-14, W3: 15-21, W4: 22-akhir)
    final List<double> weeklyIncome = [0.0, 0.0, 0.0, 0.0];
    final List<double> weeklyExpense = [0.0, 0.0, 0.0, 0.0];

    for (final t in txs) {
      final day = t.date.day;
      int weekIdx = 0;
      if (day <= 7) {
        weekIdx = 0;
      } else if (day <= 14) {
        weekIdx = 1;
      } else if (day <= 21) {
        weekIdx = 2;
      } else {
        weekIdx = 3;
      }

      if (t.isIncome) {
        weeklyIncome[weekIdx] += t.amount;
      } else {
        weeklyExpense[weekIdx] += t.amount;
      }
    }

    double maxY = 0.0;
    for (int i = 0; i < 4; i++) {
      maxY = max(maxY, max(weeklyIncome[i], weeklyExpense[i]));
    }
    if (maxY <= 0) maxY = 1000000;
    maxY = maxY * 1.25; // Beri ruang di atas bar

    final barGroups = <BarChartGroupData>[];
    final weekLabels = ['Mgg 1\n(1-7)', 'Mgg 2\n(8-14)', 'Mgg 3\n(15-21)', 'Mgg 4\n(22+)'];

    for (int i = 0; i < 4; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Batang Pemasukan (Hijau)
            BarChartRodData(
              toY: weeklyIncome[i],
              color: AppTheme.accentEmerald,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            // Batang Pengeluaran (Merah)
            BarChartRodData(
              toY: weeklyExpense[i],
              color: AppTheme.accentRose,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grafik Batang: Arus Kas Mingguan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              // Legend Singkat
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accentEmerald, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Masuk', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10)),
                  const SizedBox(width: 10),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accentRose, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Keluar', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncomeRod = rodIndex == 0;
                      final typeName = isIncomeRod ? 'Pemasukan' : 'Pengeluaran';
                      return BarTooltipItem(
                        '$typeName\n${CurrencyFormatter.formatRupiah(rod.toY)}',
                        TextStyle(
                          color: isIncomeRod ? AppTheme.accentEmerald : AppTheme.accentRose,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                        _touchedBarGroupIndex = -1;
                        return;
                      }
                      _touchedBarGroupIndex = response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          CurrencyFormatter.formatCompact(val),
                          style: const TextStyle(color: Colors.white38, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < weekLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              weekLabels[idx],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GRAFIK LINGKARAN (PIE CHART) ====================
  Widget _buildPieChartCard(List<TransactionModel> txs) {
    final expenses = txs.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, color: Colors.white24, size: 44),
              const SizedBox(height: 8),
              Text('Belum ada data pengeluaran untuk dianalisis', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final Map<String, double> categorySums = {};
    final Map<String, Color> categoryColors = {};
    double totalExpense = 0.0;

    for (final tx in expenses) {
      final catName = tx.category?.name ?? 'Lain-lain';
      categorySums[catName] = (categorySums[catName] ?? 0.0) + tx.amount;
      categoryColors[catName] = tx.category?.color ?? const Color(0xFFF43F5E);
      totalExpense += tx.amount;
    }

    final pieSections = <PieChartSectionData>[];
    int idx = 0;
    categorySums.forEach((catName, sum) {
      final isTouched = idx == _touchedPieIndex;
      final radius = isTouched ? 50.0 : 42.0;
      final percentage = (sum / totalExpense * 100).toStringAsFixed(1);
      final color = categoryColors[catName] ?? AppTheme.accentRose;

      pieSections.add(
        PieChartSectionData(
          color: color,
          value: sum,
          title: '$percentage%',
          radius: radius,
          titleStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      idx++;
    });

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grafik Lingkaran: Proporsi Pengeluaran', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: pieSections,
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend Kategori List
          ...categorySums.entries.map((entry) {
            final color = categoryColors[entry.key] ?? AppTheme.accentRose;
            final percent = (entry.value / totalExpense * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                  Text('$percent% • ${CurrencyFormatter.formatRupiah(entry.value)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required Color color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: isBold ? Colors.white : AppTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(color: color, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 15 : 13)),
        ],
      ),
    );
  }
}
