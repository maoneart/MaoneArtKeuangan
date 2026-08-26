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
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentMonth = ref.watch(selectedMonthProvider);

    final parts = currentMonth.split('-');
    final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final periodLabel = AppDateFormatter.formatMonthYear(monthDate);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // 3. Diagram Lingkaran (Pie Chart) Pengeluaran per Kategori
            transactionsAsync.when(
              data: (txs) {
                final expenses = txs.where((t) => t.isExpense).toList();
                if (expenses.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.pie_chart_outline_rounded, color: Colors.white24, size: 48),
                          const SizedBox(height: 10),
                          Text('Belum ada data pengeluaran untuk dianalisis', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                // Hitung total per kategori
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
                  final isTouched = idx == _touchedIndex;
                  final radius = isTouched ? 48.0 : 40.0;
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
                      Text('Proporsi Pengeluaran per Kategori', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
