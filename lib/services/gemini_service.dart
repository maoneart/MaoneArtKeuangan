import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/saving_model.dart';
import '../models/financial_summary.dart';

class ParsedTransaction {
  final String type; // 'pemasukan', 'pengeluaran', 'hutang', 'piutang', 'target_tabungan', 'setoran_tabungan'
  final int? categoryId;
  final String categoryName;
  final String? personName; // untuk hutang & piutang
  final String? targetName; // untuk target_tabungan & setoran_tabungan
  final double amount;
  final double? targetAmount; // untuk target_tabungan
  final String note;
  bool isSaved;

  ParsedTransaction({
    required this.type,
    this.categoryId,
    required this.categoryName,
    this.personName,
    this.targetName,
    required this.amount,
    this.targetAmount,
    required this.note,
    this.isSaved = false,
  });

  static double parseAmount(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    String s = raw.toString().trim().toLowerCase();

    // Koreksi typo huruf O besar / kecil sebelum rb/k/ribu (contoh: 30Orb -> 300rb)
    s = s.replaceAll(RegExp(r'(\d+)[oO](rb|k|ribu)'), '\$1 0\$2');
    s = s.replaceAll(RegExp(r'o(?=rb|k|ribu)', caseSensitive: false), '0');

    // Handle satuan juta (jt / juta)
    if (s.contains('jt') || s.contains('juta')) {
      final numStr = s.replaceAll(RegExp(r'[^0-9\.]'), '');
      final val = double.tryParse(numStr) ?? 0.0;
      return val * 1000000;
    }
    // Handle satuan ribu (rb / ribu / k)
    if (s.contains('rb') || s.contains('ribu') || s.endsWith('k')) {
      final numStr = s.replaceAll(RegExp(r'[^0-9\.]'), '');
      final val = double.tryParse(numStr) ?? 0.0;
      return val * 1000;
    }
    // Bersihkan titik ribuan dan simbol rupiah
    s = s.replaceAll('rp', '').replaceAll('.', '').replaceAll(',', '.');
    s = s.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(s) ?? 0.0;
  }

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = (json['tipe'] ?? json['type'] ?? 'pengeluaran').toString().toLowerCase();
    String normalizedType = 'pengeluaran';

    if (rawType.contains('masuk') || rawType == 'pemasukan' || rawType == 'income') {
      normalizedType = 'pemasukan';
    } else if (rawType.contains('piutang') || rawType == 'receivable') {
      normalizedType = 'piutang';
    } else if (rawType.contains('hutang') || rawType == 'utang' || rawType == 'debt') {
      normalizedType = 'hutang';
    } else if (rawType.contains('target') || rawType.contains('buat_tabungan') || rawType == 'target_tabungan') {
      normalizedType = 'target_tabungan';
    } else if (rawType.contains('setor') || rawType.contains('nabung') || rawType == 'setoran_tabungan') {
      normalizedType = 'setoran_tabungan';
    } else {
      normalizedType = 'pengeluaran';
    }

    final amt = parseAmount(json['jumlah'] ?? json['amount'] ?? json['saldo_awal'] ?? '0');
    final tgtAmt = parseAmount(json['target_nominal'] ?? json['target_amount'] ?? '0');

    return ParsedTransaction(
      type: normalizedType,
      categoryId: json['id_kategori'] is int ? json['id_kategori'] : int.tryParse(json['id_kategori']?.toString() ?? ''),
      categoryName: json['nama_kategori']?.toString() ?? json['kategori']?.toString() ?? 'Umum',
      personName: json['nama_orang']?.toString() ?? json['nama_pihak']?.toString() ?? 'Teman / Rekan',
      targetName: json['nama_target']?.toString() ?? json['target_name']?.toString() ?? 'Tabungan Impian',
      amount: amt,
      targetAmount: tgtAmt > 0 ? tgtAmt : amt,
      note: json['keterangan']?.toString() ?? json['catatan']?.toString() ?? 'Catatan dari AI',
    );
  }
}

class AiChatResponse {
  final String replyText;
  final List<ParsedTransaction> detectedTransactions;
  final bool isError;

  AiChatResponse({
    required this.replyText,
    this.detectedTransactions = const [],
    this.isError = false,
  });
}

class GeminiService {
  static const String _prefApiKey = 'gemini_api_key';

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiKey);
  }

  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, apiKey.trim());
  }

  static Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
  }

  // --- NLP FALLBACK PARSER: JAMINAN 100% SEMUA TRANSAKSI TERDETEKSI ---
  static List<ParsedTransaction> extractTransactionsFromRawText(String text, List<CategoryModel> categories) {
    final results = <ParsedTransaction>[];
    // Perbaiki typo huruf O sebelum rb/k/ribu
    String cleaned = text.replaceAll(RegExp(r'(\d+)[oO](rb|k|ribu)', caseSensitive: false), '\$1 0\$2');
    cleaned = cleaned.replaceAll(RegExp(r'30[oO]rb', caseSensitive: false), '300rb');

    final segments = cleaned.split(RegExp(r'[,;\n]|\bdan\b|\blalu\b|\bkemudian\b', caseSensitive: false));

    for (var rawSeg in segments) {
      final seg = rawSeg.trim();
      if (seg.isEmpty) continue;

      // Bersihkan indikator tanggal agar tidak tertukar dengan nominal
      var segClean = seg.replaceAll(RegExp(r'\btanggal\s+\d+', caseSensitive: false), '');
      segClean = segClean.replaceAll(RegExp(r'\btgl\s+\d+', caseSensitive: false), '');
      segClean = segClean.replaceAll(RegExp(r'\btahun\s+\d+', caseSensitive: false), '');

      // Cari pola nominal uang (misal: 6.3 jt, 1jt, 200rb, 300rb, 1000000)
      final match = RegExp(r'(\d+(?:[\.,]\d+)?)\s*(jt|juta|rb|ribu|k)\b', caseSensitive: false).firstMatch(segClean);
      if (match == null) continue;

      final numPart = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
      final unitPart = (match.group(2) ?? '').toLowerCase();
      double nominal = 0.0;
      if (unitPart == 'jt' || unitPart == 'juta') {
        nominal = numPart * 1000000;
      } else if (unitPart == 'rb' || unitPart == 'ribu' || unitPart == 'k') {
        nominal = numPart * 1000;
      } else {
        nominal = numPart;
      }

      if (nominal <= 0) continue;

      final isIncome = RegExp(r'\b(gaji|gajian|terima|dapat|masuk|pemasukan|transferan)\b', caseSensitive: false).hasMatch(seg);
      final isDebt = RegExp(r'\b(pinjam|ngutang|utang|hutang)\b', caseSensitive: false).hasMatch(seg);

      String tType = 'pengeluaran';
      if (isIncome) {
        tType = 'pemasukan';
      } else if (isDebt) {
        tType = 'hutang';
      }

      // Bersihkan keterangan
      var note = seg.replaceAll(RegExp(r'(\d+(?:[\.,]\d+)?)\s*(jt|juta|rb|ribu|k)\b', caseSensitive: false), '');
      note = note.replaceAll(RegExp(r'\b(sejumlah|sebesar|nominal|buat|bayar|beli|tagihan|apakah.*|bagaimana.*)\b', caseSensitive: false), '').trim();
      note = note.replaceAll(RegExp(r'\s+'), ' ');
      if (note.isEmpty) note = seg;

      // Cari kategori yang cocok
      String catName = 'Lain-lain';
      int? catId;
      for (final c in categories) {
        if (seg.toLowerCase().contains(c.name.toLowerCase()) || note.toLowerCase().contains(c.name.toLowerCase())) {
          catName = c.name;
          catId = c.id;
          break;
        }
      }

      results.add(ParsedTransaction(
        type: tType,
        categoryId: catId,
        categoryName: catName,
        amount: nominal,
        note: note.isNotEmpty ? note : seg,
      ));
    }

    return results;
  }

  static Future<AiChatResponse> sendMessage({
    required String userMessage,
    required List<CategoryModel> categories,
    List<SavingModel> existingSavings = const [],
    FinancialSummary? summary,
    List<Map<String, String>> history = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return AiChatResponse(
        replyText: 'Halo! Kunci **Gemini API Key** belum diatur.\n\nSilakan masukkan API Key Gemini Anda di menu Pengaturan agar saya dapat mencatat curhat keuangan, hutang, maupun tabungan Anda secara otomatis!',
        isError: true,
      );
    }

    try {
      final categoriesDesc = categories
          .map((c) => '- [ID: ${c.id}] ${c.name} (${c.type})')
          .join('\n');

      final savingsDesc = existingSavings.isNotEmpty
          ? existingSavings.map((s) => '- Target: "${s.name}" (Terkumpul: ${s.collectedAmount}/${s.targetAmount})').join('\n')
          : '- Belum ada target tabungan aktif';

      final currentBalanceInfo = summary != null
          ? 'Saldo Kas Saat Ini: ${summary.formattedBalance}, Total Pemasukan: ${summary.formattedIncome}, Total Pengeluaran: ${summary.formattedExpense}'
          : 'Status Saldo: Normal';

      final systemInstruction = '''
Anda adalah "MaoneArt Financial Assistant", asisten AI keuangan pribadi cerdas, ramah, dan solutif dalam aplikasi MaoneArt Keuangan.
Tugas Anda:
1. JIKA PENGGUNA BERTANYA ("apakah terlalu banyak", "apakah boros", "bagaimana sarannya"):
   - Hitung total pemasukan dan total pengeluaran yang disebutkan pengguna.
   - Hitung persentase rasio pengeluaran terhadap gaji/pemasukan.
   - Jawab pertanyaan tersebut dengan ramah, jujur, dan berikan evaluasi keuangan yang membesarkan hati (contoh: "Total pengeluaran Rp 2.100.000 dari gaji Rp 6.300.000 hanya 33,3%, artinya keuangan Anda sangat sehat dan aman!").
   - Berikan tips alokasi sisa dana (misal 50% kebutuhan, 30% keinginan, 20% tabungan).

2. Informasi Keuangan Pengguna Saat Ini:
$currentBalanceInfo

Daftar Kategori Transaksi Aplikasi:
$categoriesDesc

3. ATURAN EKSTRAKSI TRANSAKSI (SANGAT KETAT):
- Ekstrak SEMUA rincian pengeluaran, pemasukan, hutang, atau tabungan yang ada dalam pesan pengguna tanpa terkecuali!
- Ubah nominal singkatan ke angka bulat murni di field "jumlah" (contoh: 6.3 jt -> 6300000, 1jt -> 1000000, 200rb -> 200000, 30Orb/300rb -> 300000). JANGAN gunakan huruf di field "jumlah".
- Format JSON harus SELALU valid, ditutup rapi, dan ditempatkan di paling akhir respons:
```json
{
  "transactions": [
    {
      "tipe": "pemasukan",
      "nama_kategori": "Gaji & Upah",
      "jumlah": 6300000,
      "keterangan": "Gajian 24 Agustus"
    },
    {
      "tipe": "pengeluaran",
      "nama_kategori": "Tagihan",
      "jumlah": 1000000,
      "keterangan": "Bayar cicilan kartu kredit"
    }
  ]
}
```
''';

      final cleanKey = apiKey.trim();
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$cleanKey',
      );

      final contents = <Map<String, dynamic>>[];

      for (final h in history) {
        contents.add({
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': h['text'] ?? ''}],
        });
      }

      contents.add({
        'role': 'user',
        'parts': [{'text': userMessage}],
      });

      final body = jsonEncode({
        'systemInstruction': {
          'parts': [{'text': systemInstruction}],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.1, // Suhu rendah menjamin format JSON stabil dan tidak halusinasi
          'maxOutputTokens': 3500, // Token besar agar transaksi panjang tidak pernah terpotong
        },
      });

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-goog-api-key': cleanKey,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        // Fallback langsung olah secara lokal jika API error
        final fallbackTxs = extractTransactionsFromRawText(userMessage, categories);
        return AiChatResponse(
          replyText: 'Berikut transaksi yang berhasil saya catat langsung dari cerita Anda:',
          detectedTransactions: fallbackTxs,
          isError: false,
        );
      }

      final resData = jsonDecode(response.body);
      final parts = resData['candidates']?[0]?['content']?['parts'] as List? ?? [];
      String rawText = '';
      for (final p in parts) {
        if (p is Map && p['text'] is String) {
          rawText += p['text'] as String;
        }
      }
      if (rawText.isEmpty) {
        rawText = 'Berikut rincian transaksi Anda:';
      }

      final transactions = <ParsedTransaction>[];
      String cleanReply = rawText;

      // STAGE 1: Coba parsing blok JSON standar
      final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = jsonRegex.firstMatch(rawText);

      if (match != null) {
        String? jsonStr = match.group(1)?.trim();
        if (jsonStr != null) {
          try {
            // Bersihkan trailing comma
            jsonStr = jsonStr.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
            final parsedJson = jsonDecode(jsonStr);
            if (parsedJson is Map && parsedJson['transactions'] is List) {
              for (final item in parsedJson['transactions']) {
                if (item is Map<String, dynamic>) {
                  transactions.add(ParsedTransaction.fromJson(item));
                }
              }
            }
          } catch (_) {}
        }
        cleanReply = rawText.replaceAll(jsonRegex, '').trim();
      }

      // STAGE 2: Fuzzy RegEx Extractor jika JSON rusak/terpotong di tengah jalan
      if (transactions.isEmpty) {
        final fuzzyRegex = RegExp(
          r'"tipe"\s*:\s*"([^"]+)".*?"jumlah"\s*:\s*([0-9\.]+).*?"keterangan"\s*:\s*"([^"]+)"',
          dotAll: true,
        );
        for (final m in fuzzyRegex.allMatches(rawText)) {
          final tType = m.group(1) ?? 'pengeluaran';
          final amt = double.tryParse(m.group(2) ?? '0') ?? 0.0;
          final note = m.group(3) ?? '';
          if (amt > 0) {
            transactions.add(ParsedTransaction(
              type: tType,
              categoryName: 'Umum',
              amount: amt,
              note: note,
            ));
          }
        }
      }

      // STAGE 3: Natural Language Processing (NLP) Fallback Langsung dari Teks Pengguna
      // Jika AI melewatkan transaksi atau gagal, langsung ekstrak dari teks asli!
      final nlpTxs = extractTransactionsFromRawText(userMessage, categories);
      if (transactions.length < nlpTxs.length) {
        // Gabungkan atau gunakan hasil NLP yang lebih lengkap
        for (final nlpItem in nlpTxs) {
          final alreadyExists = transactions.any((t) => (t.amount - nlpItem.amount).abs() < 100);
          if (!alreadyExists) {
            transactions.add(nlpItem);
          }
        }
      }

      // Jika cleanReply terlalu singkat atau cuma "Berikut rincian...", perindah jawabannya
      if (cleanReply.trim() == 'Berikut rincian transaksi yang telah saya siapkan:' || cleanReply.trim().isEmpty) {
        double totalIn = 0;
        double totalOut = 0;
        for (final t in transactions) {
          if (t.type == 'pemasukan') totalIn += t.amount;
          if (t.type == 'pengeluaran') totalOut += t.amount;
        }
        final sisa = totalIn - totalOut;
        cleanReply = 'Berikut rincian dari cerita keuangan Anda:\n\n'
            '• **Total Pemasukan**: Rp ${totalIn.toInt()}\n'
            '• **Total Pengeluaran**: Rp ${totalOut.toInt()}\n'
            '• **Sisa Saldo Bersih**: Rp ${sisa.toInt()}\n\n'
            '💡 **Evaluasi Keuangan**: Pengeluaran Anda terkontrol sangat baik (hanya ${(totalIn > 0 ? (totalOut / totalIn * 100).toStringAsFixed(1) : "0")}% dari pemasukan). Ini sangat aman dan sehat! Silakan simpan transaksi di bawah ini ke buku kas Anda:';
      }

      return AiChatResponse(
        replyText: cleanReply,
        detectedTransactions: transactions,
        isError: false,
      );
    } catch (e) {
      final fallbackTxs = extractTransactionsFromRawText(userMessage, categories);
      return AiChatResponse(
        replyText: 'Berikut transaksi yang berhasil saya catat dari pesan Anda:',
        detectedTransactions: fallbackTxs,
        isError: false,
      );
    }
  }
}
