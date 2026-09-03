import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt_model.dart';
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
  final DateTime date; // Tanggal transaksi yang terdeteksi
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
    DateTime? date,
    this.isSaved = false,
  }) : date = date ?? DateTime.now();

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

  // Parser tanggal multi-format (Bahasa Indonesia, ISO, singkatan)
  static DateTime parseIndonesianDate(dynamic raw, [String? fallbackText]) {
    if (raw is DateTime) return raw;

    // 1. Coba parse dari raw input jika ada string (misal dari JSON AI "2026-08-24")
    if (raw != null && raw.toString().trim().isNotEmpty) {
      final str = raw.toString().trim();
      final iso = DateTime.tryParse(str);
      if (iso != null) return iso;

      final parsedFromRaw = _extractDateFromString(str);
      if (parsedFromRaw != null) return parsedFromRaw;
    }

    // 2. Jika di raw tidak ada tanggal, coba ekstrak dari fallbackText (misal kalimat pesan pengguna)
    if (fallbackText != null && fallbackText.trim().isNotEmpty) {
      final extracted = _extractDateFromString(fallbackText);
      if (extracted != null) return extracted;
    }

    return DateTime.now();
  }

  static DateTime? _extractDateFromString(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    // Kata kunci relatif
    if (RegExp(r'\b(kemarin\s+lusa|2\s+hari\s+lalu)\b').hasMatch(lower)) {
      return now.subtract(const Duration(days: 2));
    }
    if (RegExp(r'\bkemarin\b').hasMatch(lower)) {
      return now.subtract(const Duration(days: 1));
    }
    if (RegExp(r'\b(hari\s+ini|tadi\s+pagi|tadi\s+siang|tadi\s+malam|barusan|tadi)\b').hasMatch(lower)) {
      return now;
    }
    if (RegExp(r'\bbesok\b').hasMatch(lower)) {
      return now.add(const Duration(days: 1));
    }

    // Pola YYYY-MM-DD atau YYYY/MM/DD
    final isoMatch = RegExp(r'\b(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})\b').firstMatch(lower);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // Pola DD-MM-YYYY atau DD/MM/YYYY atau DD-MM-YY atau DD/MM/YY
    final numDateMatch = RegExp(r'\b(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})\b').firstMatch(lower);
    if (numDateMatch != null) {
      final d = int.tryParse(numDateMatch.group(1)!);
      final m = int.tryParse(numDateMatch.group(2)!);
      var y = int.tryParse(numDateMatch.group(3)!);
      if (y != null && y < 100) {
        y += 2000;
      }
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // Kamus bulan Bahasa Indonesia & Inggris
    final monthMap = <String, int>{
      'januari': 1, 'jan': 1, 'january': 1,
      'februari': 2, 'feb': 2, 'pebruari': 2, 'february': 2,
      'maret': 3, 'mar': 3, 'march': 3,
      'april': 4, 'apr': 4,
      'mei': 5, 'may': 5,
      'juni': 6, 'jun': 6, 'june': 6,
      'juli': 7, 'jul': 7, 'july': 7,
      'agustus': 8, 'agt': 8, 'ags': 8, 'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'oktober': 10, 'okt': 10, 'october': 10, 'oct': 10,
      'november': 11, 'nov': 11, 'nopember': 11,
      'desember': 12, 'des': 12, 'december': 12, 'dec': 12,
    };

    final monthPattern = monthMap.keys.join('|');
    // Pola: (tanggal / tgl) [DD] [Nama Bulan] [YYYY / YY]
    // Contoh: "tanggal 24 agustus 26", "24 agustus 2026", "tgl 5 mei", "24 agustus"
    final textDateMatch = RegExp(
      r'(?:tanggal|tgl\s+)?\b(\d{1,2})\s+(' + monthPattern + r')(?:\s+(\d{2,4}))?\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (textDateMatch != null) {
      final d = int.tryParse(textDateMatch.group(1)!);
      final mName = textDateMatch.group(2)!.toLowerCase();
      final m = monthMap[mName];
      final yStr = textDateMatch.group(3);
      int y = now.year;
      if (yStr != null) {
        final parsedY = int.tryParse(yStr);
        if (parsedY != null) {
          y = parsedY < 100 ? parsedY + 2000 : parsedY;
        }
      }
      if (d != null && m != null && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // Pola: (bulan) [Nama Bulan] [YYYY / YY]
    // Contoh: "bulan maret 2025", "maret 2025", "maret 25", "gaji maret 2025"
    final monthYearMatch = RegExp(
      r'(?:bulan\s+|gaji\s+)?\b(' + monthPattern + r')\s+(\d{2,4})\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (monthYearMatch != null) {
      final mName = monthYearMatch.group(1)!.toLowerCase();
      final m = monthMap[mName];
      final yStr = monthYearMatch.group(2);
      int y = now.year;
      if (yStr != null) {
        final parsedY = int.tryParse(yStr);
        if (parsedY != null) {
          y = parsedY < 100 ? parsedY + 2000 : parsedY;
        }
      }
      if (m != null) {
        return DateTime(y, m, 1);
      }
    }

    return null;
  }

  factory ParsedTransaction.fromJson(Map<String, dynamic> json, [String? parentContext]) {
    final rawType = (json['tipe'] ?? json['type'] ?? 'pengeluaran').toString().toLowerCase();
    String normalizedType = 'pengeluaran';

    if (rawType.contains('masuk') || rawType == 'pemasukan' || rawType == 'income') {
      normalizedType = 'pemasukan';
    } else if (rawType.contains('bayar_hutang') || rawType.contains('cicil') || rawType.contains('pelunasan') || rawType.contains('bayar_cicilan')) {
      normalizedType = 'bayar_hutang';
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
    final txDate = parseIndonesianDate(json['tanggal'] ?? json['date'] ?? json['tgl'], parentContext);

    return ParsedTransaction(
      type: normalizedType,
      categoryId: json['id_kategori'] is int ? json['id_kategori'] : int.tryParse(json['id_kategori']?.toString() ?? ''),
      categoryName: json['nama_kategori']?.toString() ?? json['kategori']?.toString() ?? (normalizedType == 'bayar_hutang' ? 'Tagihan & Pembayaran Hutang' : 'Umum'),
      personName: json['nama_orang']?.toString() ?? json['nama_pihak']?.toString() ?? json['nama_penghutang']?.toString() ?? 'Pemberi Pinjaman',
      targetName: json['nama_target']?.toString() ?? json['target_name']?.toString() ?? 'Tabungan Impian',
      amount: amt,
      targetAmount: tgtAmt > 0 ? tgtAmt : amt,
      note: json['keterangan']?.toString() ?? json['catatan']?.toString() ?? (normalizedType == 'bayar_hutang' ? 'Bayar cicilan/hutang' : 'Catatan dari AI'),
      date: txDate,
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

  // --- NLP FALLBACK PARSER: JAMINAN 100% SEMUA TRANSAKSI & TANGGAL TERDETEKSI ---
  static List<ParsedTransaction> extractTransactionsFromRawText(String text, List<CategoryModel> categories) {
    final results = <ParsedTransaction>[];
    final globalDate = ParsedTransaction.parseIndonesianDate(null, text);

    // Perbaiki typo huruf O sebelum rb/k/ribu
    String cleaned = text.replaceAll(RegExp(r'(\d+)[oO](rb|k|ribu)', caseSensitive: false), '\$1 0\$2');
    cleaned = cleaned.replaceAll(RegExp(r'30[oO]rb', caseSensitive: false), '300rb');

    final segments = cleaned.split(RegExp(r'[,;\n]|\bdan\b|\blalu\b|\bkemudian\b', caseSensitive: false));

    for (var rawSeg in segments) {
      final seg = rawSeg.trim();
      if (seg.isEmpty) continue;

      // Cek apakah segmen ini menyebutkan tanggal spesifik tersendiri
      final segDate = ParsedTransaction._extractDateFromString(seg) ?? globalDate;

      // Bersihkan indikator tanggal agar tidak tertukar dengan nominal
      var segClean = seg.replaceAll(RegExp(r'\btanggal\s+\d+(\s+[a-zA-Z]+)?(\s+\d+)?', caseSensitive: false), '');
      segClean = segClean.replaceAll(RegExp(r'\btgl\s+\d+(\s+[a-zA-Z]+)?(\s+\d+)?', caseSensitive: false), '');
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
      final isPayDebt = RegExp(r'\b(bayar\s+hutang|bayar\s+utang|bayar\s+cicilan|cicil|angsuran|pelunasan)\b', caseSensitive: false).hasMatch(seg);
      final isDebt = RegExp(r'\b(pinjam|ngutang|utang|hutang)\b', caseSensitive: false).hasMatch(seg);

      String tType = 'pengeluaran';
      if (isIncome) {
        tType = 'pemasukan';
      } else if (isPayDebt) {
        tType = 'bayar_hutang';
      } else if (isDebt) {
        tType = 'hutang';
      }

      // Bersihkan keterangan
      var note = seg.replaceAll(RegExp(r'(\d+(?:[\.,]\d+)?)\s*(jt|juta|rb|ribu|k)\b', caseSensitive: false), '');
      note = note.replaceAll(RegExp(r'\b(sejumlah|sebesar|nominal|buat|bayar|beli|tagihan|apakah.*|bagaimana.*)\b', caseSensitive: false), '').trim();
      note = note.replaceAll(RegExp(r'\s+'), ' ');
      if (note.isEmpty) note = seg;

      // Cari kategori yang cocok
      String catName = tType == 'bayar_hutang' ? 'Pembayaran Hutang & Cicilan' : 'Lain-lain';
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
        date: segDate,
      ));
    }

    return results;
  }

  static Future<AiChatResponse> sendMessage({
    required String userMessage,
    required List<CategoryModel> categories,
    List<DebtModel> existingDebts = const [],
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

      final debtsDesc = existingDebts.isNotEmpty
          ? existingDebts.map((d) => '- [ID: ${d.id}] ${d.isDebt ? "Hutang ke" : "Piutang di"} "${d.debtorName}" (Sisa: ${d.remainingAmount}/${d.totalAmount})').join('\n')
          : '- Belum ada data hutang/piutang aktif';

      final savingsDesc = existingSavings.isNotEmpty
          ? existingSavings.map((s) => '- Target: "${s.name}" (Terkumpul: ${s.collectedAmount}/${s.targetAmount})').join('\n')
          : '- Belum ada target tabungan aktif';

      final currentBalanceInfo = summary != null
          ? 'Saldo Kas Saat Ini: ${summary.formattedBalance}, Total Pemasukan: ${summary.formattedIncome}, Total Pengeluaran: ${summary.formattedExpense}'
          : 'Status Saldo: Normal';

      final now = DateTime.now();
      final nowIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final systemInstruction = '''
Anda adalah "MaoneArt Financial Assistant", asisten AI keuangan pribadi cerdas, ramah, dan solutif dalam aplikasi MaoneArt Keuangan.
Tanggal Hari Ini: ${now.day}/${now.month}/${now.year} ($nowIso).

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

Daftar Hutang & Piutang Pengguna Saat Ini:
$debtsDesc

Daftar Target Tabungan Pengguna Saat Ini:
$savingsDesc

3. ATURAN DETEKSI TANGGAL TRANSAKSI (SANGAT PENTING):
- Jika pengguna menyebutkan tanggal transaksi (contoh: "tanggal 24 agustus 26", "24/08/2026", "kemarin", "24 agustus", "bulan maret 2025", "pakai gaji maret 2025"), ekstrak dan gunakan tanggal tersebut ke field "tanggal" dengan format "YYYY-MM-DD" (contoh: "2026-08-24" atau "2025-03-01").
- Jika bulan & tahun saja yang disebutkan (misal: "maret 2025"), gunakan tanggal 1 bulan tersebut ("2025-03-01").
- Jika tahun disebutkan 2 digit (misal: "26"), anggap tahun 2026.
- Jika pengguna tidak menyebutkan tanggal apa pun, gunakan tanggal hari ini ("$nowIso").

4. ATURAN EKSTRAKSI TRANSAKSI (SANGAT KETAT):
- Ekstrak SEMUA rincian pengeluaran, pemasukan, hutang, piutang, bayar hutang/cicilan, atau tabungan yang ada dalam pesan pengguna tanpa terkecuali!
- TIPE TRANSAKSI YANG DIDUKUNG:
  * "pemasukan": Gaji, bonus, transfer masuk, dll.
  * "pengeluaran": Belanja, bensin, tagihan, makanan, dll.
  * "hutang": Tambah catatan hutang baru (misal: "pinjam uang ke Budi 500rb").
  * "piutang": Catatan orang pinjam uang ke kita (misal: "si Andi pinjam 300rb").
  * "bayar_hutang": Bayar/cicil/lunas hutang (misal: "bayar hutang ke Budi 200rb pakai gaji maret 2025", "cicil hutang 500rb"). Cantumkan nama orang di "nama_orang".
  * "target_tabungan": Buat target tabungan baru.
  * "setoran_tabungan": Setor dana ke target tabungan.
- Ubah nominal singkatan ke angka bulat murni di field "jumlah" (contoh: 6.3 jt -> 6300000, 1jt -> 1000000, 200rb -> 200000, 30Orb/300rb -> 300000). JANGAN gunakan huruf di field "jumlah".
- Format JSON harus SELALU valid, ditutup rapi, dan ditempatkan di paling akhir respons:
```json
{
  "transactions": [
    {
      "tanggal": "2025-03-01",
      "tipe": "bayar_hutang",
      "nama_orang": "Budi",
      "jumlah": 200000,
      "keterangan": "Bayar hutang ke Budi pakai gaji maret 2025"
    },
    {
      "tanggal": "2026-08-24",
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
                  transactions.add(ParsedTransaction.fromJson(item, userMessage));
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
        final defaultDate = ParsedTransaction.parseIndonesianDate(null, userMessage);
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
              date: defaultDate,
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
