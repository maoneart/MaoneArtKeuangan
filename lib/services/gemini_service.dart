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

    final amt = double.tryParse(json['jumlah']?.toString() ?? json['amount']?.toString() ?? json['saldo_awal']?.toString() ?? '0') ?? 0.0;
    final tgtAmt = double.tryParse(json['target_nominal']?.toString() ?? json['target_amount']?.toString() ?? '0') ?? (amt > 0 ? amt : 0.0);

    return ParsedTransaction(
      type: normalizedType,
      categoryId: json['id_kategori'] is int ? json['id_kategori'] : int.tryParse(json['id_kategori']?.toString() ?? ''),
      categoryName: json['nama_kategori']?.toString() ?? 'Lain-lain',
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
1. Dengarkan curhat, cerita transaksi, hutang, piutang, tabungan, atau pertanyaan keuangan pengguna dalam bahasa Indonesia yang akrab dan santun.
2. Informasi Keuangan Pengguna Saat Ini:
$currentBalanceInfo

Daftar Kategori Transaksi Aplikasi:
$categoriesDesc

Daftar Target Tabungan Pengguna yang Sudah Ada:
$savingsDesc

3. ATURAN ANALISIS & DETEKSI TRANSAKSI:
Analisis pesan pengguna untuk mendeteksi 5 jenis transaksi berikut:
- **pengeluaran**: Saat pengguna belanja, makan, beli barang, bayar tagihan, servis, sedekah, dsb.
- **pemasukan**: Saat pengguna menerima gaji, transferan uang, hasil jualan, bonus, dsb.
- **hutang**: Saat pengguna meminjam uang dari orang lain / bank / pinjol / kartu kredit (contoh: "pinjam uang ke Budi 500rb").
- **piutang**: Saat orang lain meminjam uang ke pengguna (contoh: "si Joko minjam uang ke saya 200rb").
- **target_tabungan**: Saat pengguna ingin membuat target impian tabungan baru (contoh: "saya mau bikin target nabung beli Laptop 10 juta").
- **setoran_tabungan**: Saat pengguna menabung atau menyisihkan uang ke tabungan tertentu (contoh: "nabung 100rb buat tabungan Laptop").

Jika terdeteksi satu atau lebih transaksi di atas, Anda WAJIB menyertakan blok JSON di akhir respons Anda persis dengan format berikut:
```json
{
  "transactions": [
    {
      "tipe": "pengeluaran",
      "id_kategori": 1,
      "nama_kategori": "Makanan & Minuman",
      "jumlah": 25000,
      "keterangan": "Makan siang"
    },
    {
      "tipe": "pemasukan",
      "id_kategori": 2,
      "nama_kategori": "Gaji & Upah",
      "jumlah": 3000000,
      "keterangan": "Gaji bulanan"
    },
    {
      "tipe": "hutang",
      "nama_orang": "Budi",
      "jumlah": 500000,
      "keterangan": "Pinjam uang benerin motor"
    },
    {
      "tipe": "piutang",
      "nama_orang": "Joko",
      "jumlah": 200000,
      "keterangan": "Joko minjam uang"
    },
    {
      "tipe": "target_tabungan",
      "nama_target": "Beli Laptop Baru",
      "target_nominal": 10000000,
      "saldo_awal": 0,
      "keterangan": "Target nabung beli laptop"
    },
    {
      "tipe": "setoran_tabungan",
      "nama_target": "Beli Laptop Baru",
      "jumlah": 100000,
      "keterangan": "Setor tabungan laptop"
    }
  ]
}
```
Jika tidak ada transaksi (hanya ngobrol/konsultasi biasa), JANGAN sertakan blok json transactions.
Berikan tanggapan singkat, ramah, dan memotivasi sebelum blok JSON.
''';

      final cleanKey = apiKey.trim();
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$cleanKey',
      );

      final contents = <Map<String, dynamic>>[];

      // Tambahkan history percakapan
      for (final h in history) {
        contents.add({
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': h['text'] ?? ''}],
        });
      }

      // Tambahkan pesan pengguna saat ini
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
          'temperature': 0.4,
          'maxOutputTokens': 1200,
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
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? 'Gagal menghubungi Gemini API (${response.statusCode})';
        return AiChatResponse(
          replyText: 'Maaf, terjadi kendala saat menghubungi AI: $errMsg\n\nPastikan API Key Gemini Anda aktif di Google AI Studio.',
          isError: true,
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
        rawText = 'Tidak ada tanggapan dari AI.';
      }

      // Ekstrak JSON Transaksi dari rawText jika ada
      final transactions = <ParsedTransaction>[];
      String cleanReply = rawText;

      final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = jsonRegex.firstMatch(rawText);

      if (match != null) {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null) {
          try {
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
        // Hapus blok JSON dari teks tampilan chat agar chat bubble tetap bersih
        cleanReply = rawText.replaceAll(jsonRegex, '').trim();
      }

      return AiChatResponse(
        replyText: cleanReply.isNotEmpty ? cleanReply : 'Berikut transaksi yang berhasil saya rangkum dari cerita Anda:',
        detectedTransactions: transactions,
        isError: false,
      );
    } catch (e) {
      return AiChatResponse(
        replyText: 'Koneksi error: $e\n\nPastikan ponsel Anda terhubung ke internet saat menggunakan fitur Chat AI.',
        isError: true,
      );
    }
  }
}
