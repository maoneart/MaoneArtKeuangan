import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class CsvExportService {
  static Future<String> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    final List<List<dynamic>> rows = [
      ['No', 'Tanggal', 'Tipe', 'Kategori', 'Jumlah (Rp)', 'Keterangan'],
    ];

    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      rows.add([
        i + 1,
        AppDateFormatter.toDbDate(t.date),
        t.type.toUpperCase(),
        t.category?.name ?? 'Umum',
        t.amount,
        t.note ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Transaksi_Keuangan_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    return file.path;
  }

  static Future<void> shareCsv(String path) async {
    await Share.shareXFiles([XFile(path)], subject: 'Export Transaksi Keuangan (CSV / Excel)');
  }
}
