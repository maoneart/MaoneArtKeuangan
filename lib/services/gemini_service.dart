import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/financial_summary.dart';

class ParsedTransaction {
  final String type; // 'pemasukan' atau 'pengeluaran'
  final int? categoryId;
  final String categoryName;
  final double amount;
  final String note;
  bool isSaved;

  ParsedTransaction({
    required this.type,
    this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.note,
    this.isSaved = false,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      type: json['tipe']?.toString().toLowerCase() == 'pemasukan' ? 'pemasukan' : 'pengeluaran',
      categoryId: json['id_kategori'] is int ? json['id_kategori'] : int.tryParse(json['id_kategori']?.toString() ?? ''),
      categoryName: json['nama_kategori']?.toString() ?? 'Lain-lain',
      amount: double.tryParse(json['jumlah']?.toString() ?? '0') ?? 0.0,
      note: json['keterangan']?.toString() ?? 'Catatan dari AI',
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
    FinancialSummary? summary,
    List<Map<String, String>> history = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return AiChatResponse(
        replyText: 'Halo! Kunci **Gemini API Key** belum diatur.\n\nSilakan masukkan API Key Gemini Anda di menu pengaturan di atas agar saya dapat mencatat curhat keuangan Anda secara otomatis!',
        isError: true,
      );
    }

    try {
      final categoriesDesc = categories
          .map((c) => '- [ID: ${c.id}] ${c.name} (${c.type})')
          .join('\n');

      final currentBalanceInfo = summary != null
          ? 'Saldo Kas Saat Ini: ${summary.formattedBalance}, Total Pemasukan: ${summary.formattedIncome}, Total Pengeluaran: ${summary.formattedExpense}'
          : 'Status Saldo: Normal';

      final systemInstruction = '''
Anda adalah "MaoneArt Financial Assistant", asisten AI keuangan pribadi cerdas dan ramah dalam aplikasi MaoneArt Keuangan.
Tugas Anda:
1. Dengarkan curhat, cerita pengeluaran/pemasukan, atau pertanyaan keuangan pengguna dalam bahasa Indonesia yang santun, akrab, dan solutif.
2. Informasi Keuangan Pengguna Saat Ini:
$currentBalanceInfo

Daftar Kategori Aplikasi:
$categoriesDesc

3. ATURAN EKSTRAKSI TRANSAKSI:
Jika pengguna menyebutkan pengeluaran atau pemasukan (contoh: "tadi makan soto 20rb dan isi bensin 30rb", atau "dapat transferan 500rb"), Anda WAJIB menganalisis dan menyertakan blok JSON di akhir respons Anda persis dengan format berikut:
```json
{
  "transactions": [
    {
      "tipe": "pengeluaran",
      "id_kategori": 1,
      "nama_kategori": "Makanan & Minuman",
      "jumlah": 20000,
      "keterangan": "Makan soto"
    }
  ]
}
```
Cocokkan id_kategori dan nama_kategori dengan daftar kategori yang ada.
Jika tidak ada transaksi (hanya konsultasi biasa), JANGAN sertakan blok json transactions.
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
          'maxOutputTokens': 1000,
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
