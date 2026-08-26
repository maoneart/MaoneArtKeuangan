import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../models/financial_summary.dart';
import '../utils/currency_formatter.dart';

class PdfExportService {
  static Future<String> generateFinancialReport({
    required String periodTitle,
    required FinancialSummary summary,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Laporan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEUANGAN PRIBADI',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Periode: $periodTitle', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  'MaoneArt Keuangan',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Ringkasan Finansial Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Pemasukan', summary.formattedIncome, PdfColors.green700),
                  _buildSummaryItem('Total Pengeluaran', summary.formattedExpense, PdfColors.red700),
                  _buildSummaryItem('Arus Kas Bersih', summary.formattedBalance, summary.netBalance >= 0 ? PdfColors.blue700 : PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Rincian Transaksi
            pw.Text(
              'Rincian Transaksi',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Kategori', 'Tipe', 'Keterangan', 'Jumlah'],
              data: transactions.map((t) => [
                t.formattedShortDate,
                t.category?.name ?? 'Umum',
                t.isIncome ? 'Pemasukan' : 'Pengeluaran',
                t.note ?? '-',
                t.formattedAmount,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Dicetak otomatis via Aplikasi MaoneArt Keuangan',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Laporan_Keuangan_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static Future<void> sharePdf(String path, {String? subject}) async {
    await Share.shareXFiles([XFile(path)], subject: subject ?? 'Laporan Keuangan');
  }
}
