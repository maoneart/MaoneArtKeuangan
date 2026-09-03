import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/saving_model.dart';
import 'database_helper.dart';
import 'gemini_service.dart';

class PhpMyAdminService {
  static const String _prefServerUrl = 'phpmyadmin_server_url';
  static const String defaultServerUrl = 'http://127.0.0.1:8085/Keuangan/api';

  static String normalizeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return defaultServerUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api') && !url.contains('/api/')) {
      url = '$url/api';
    }
    return url;
  }

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefServerUrl);
    return raw != null ? normalizeUrl(raw) : defaultServerUrl;
  }

  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalizeUrl(url);
    await prefs.setString(_prefServerUrl, normalized);
  }

  // Cek Status Server phpMyAdmin & Database db_keuangan
  static Future<Map<String, dynamic>> checkStatus([String? customUrl]) async {
    try {
      var baseUrl = customUrl != null && customUrl.trim().isNotEmpty
          ? normalizeUrl(customUrl)
          : await getServerUrl();

      final url = Uri.parse('$baseUrl/status.php');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'status': 'error', 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      // Coba fallback ganti 127.0.0.1 <-> localhost jika gagal
      try {
        var baseUrl = customUrl != null && customUrl.trim().isNotEmpty
            ? normalizeUrl(customUrl)
            : await getServerUrl();
        if (baseUrl.contains('127.0.0.1')) {
          baseUrl = baseUrl.replaceAll('127.0.0.1', 'localhost');
        } else if (baseUrl.contains('localhost')) {
          baseUrl = baseUrl.replaceAll('localhost', '127.0.0.1');
        }
        final url = Uri.parse('$baseUrl/status.php');
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return jsonDecode(res.body);
        }
      } catch (_) {}

      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server ($e)'};
    }
  }

  // Kirim transaksi baru ke phpMyAdmin secara real-time
  static Future<bool> pushTransaction(TransactionModel tx) async {
    try {
      final baseUrl = await getServerUrl();
      final url = Uri.parse('$baseUrl/transaksi.php');
      final body = jsonEncode({
        'date': tx.date.toIso8601String(),
        'type': tx.type,
        'categoryId': tx.categoryId,
        'amount': tx.amount,
        'note': tx.note ?? '',
      });
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Ambil Gemini API Key dari phpMyAdmin (app_settings)
  static Future<String?> fetchGeminiApiKey() async {
    try {
      final baseUrl = await getServerUrl();
      final url = Uri.parse('$baseUrl/settings.php?key=gemini_api_key');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final key = data['key_value']?.toString().trim();
        if (key != null && key.isNotEmpty) {
          await GeminiService.saveApiKey(key);
          return key;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Simpan Gemini API Key ke phpMyAdmin (app_settings)
  static Future<bool> saveGeminiApiKey(String apiKey) async {
    try {
      final baseUrl = await getServerUrl();
      final url = Uri.parse('$baseUrl/settings.php');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key_name': 'gemini_api_key',
          'key_value': apiKey.trim(),
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Sinkronisasi Penuh 2 Arah (Full Bidirectional Sync)
  // Menyimpan semua data lokal ke MySQL dan memulihkan data MySQL ke SQLite jika baru install ulang APK
  static Future<Map<String, dynamic>> syncFull(DatabaseHelper db) async {
    try {
      final baseUrl = await getServerUrl();
      final url = Uri.parse('$baseUrl/sync.php');

      // 1. Ambil data lokal SQLite & API Key
      final localTxs = await db.getTransactions(limit: 1000);
      final localDebts = await db.getDebts();
      final localSavings = await db.getSavings();
      final localApiKey = await GeminiService.getApiKey() ?? '';

      // 2. Buat Payload
      final payload = {
        'gemini_api_key': localApiKey,
        'transactions': localTxs.map((t) => {
          'date': t.date.toIso8601String(),
          'type': t.type,
          'categoryId': t.categoryId,
          'amount': t.amount,
          'note': t.note ?? '',
        }).toList(),
        'debts': localDebts.map((d) => {
          'debtorName': d.debtorName,
          'type': d.type,
          'totalAmount': d.totalAmount,
          'remainingAmount': d.remainingAmount,
          'status': d.status,
          'borrowDate': d.borrowDate.toIso8601String(),
          'note': d.note ?? '',
        }).toList(),
        'savings': localSavings.map((s) => {
          'name': s.name,
          'targetAmount': s.targetAmount,
          'collectedAmount': s.collectedAmount,
          'status': s.status,
          'note': s.note ?? '',
        }).toList(),
      };

      // 3. Kirim ke Server PHP
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        return {'status': 'error', 'message': 'Gagal sinkronisasi (HTTP ${res.statusCode})'};
      }

      final resData = jsonDecode(res.body);
      final serverData = resData['data'] as Map<String, dynamic>?;

      int restoredTxs = 0;
      int restoredDebts = 0;
      int restoredSavings = 0;

      // 4. Pulihkan data dari phpMyAdmin ke SQLite lokal (jika lokal masih kosong / ada data baru di phpMyAdmin)
      if (serverData != null) {
        // Transaksi
        final serverTxs = serverData['transactions'] as List? ?? [];
        for (final item in serverTxs) {
          if (item is Map<String, dynamic>) {
            final tglStr = item['date']?.toString() ?? '';
            final tgl = DateTime.tryParse(tglStr) ?? DateTime.now();
            final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            final note = item['note']?.toString() ?? '';

            final exists = localTxs.any((lt) =>
                lt.amount == amt &&
                lt.note == note &&
                lt.date.year == tgl.year &&
                lt.date.month == tgl.month &&
                lt.date.day == tgl.day);

            if (!exists) {
              await db.insertTransaction(TransactionModel(
                date: tgl,
                type: item['type']?.toString() ?? 'pengeluaran',
                categoryId: int.tryParse(item['categoryId']?.toString() ?? '1') ?? 1,
                amount: amt,
                note: note,
              ));
              restoredTxs++;
            }
          }
        }

        // Hutang
        final serverDebts = serverData['debts'] as List? ?? [];
        for (final item in serverDebts) {
          if (item is Map<String, dynamic>) {
            final name = item['debtorName']?.toString() ?? 'Rekan';
            final amt = double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0.0;

            final exists = localDebts.any((ld) => ld.debtorName == name && ld.totalAmount == amt);
            if (!exists) {
              final tgl = DateTime.tryParse(item['borrowDate']?.toString() ?? '') ?? DateTime.now();
              await db.insertDebt(DebtModel(
                debtorName: name,
                type: item['type']?.toString() ?? 'hutang',
                totalAmount: amt,
                remainingAmount: double.tryParse(item['remainingAmount']?.toString() ?? '0') ?? amt,
                status: item['status']?.toString() ?? 'belum_lunas',
                borrowDate: tgl,
                note: item['note']?.toString(),
              ));
              restoredDebts++;
            }
          }
        }

        // Tabungan
        final serverSavings = serverData['savings'] as List? ?? [];
        for (final item in serverSavings) {
          if (item is Map<String, dynamic>) {
            final name = item['name']?.toString() ?? 'Tabungan';
            final target = double.tryParse(item['targetAmount']?.toString() ?? '0') ?? 0.0;

            final exists = localSavings.any((ls) => ls.name == name);
            if (!exists) {
              await db.insertSaving(SavingModel(
                name: name,
                targetAmount: target,
                collectedAmount: double.tryParse(item['collectedAmount']?.toString() ?? '0') ?? 0.0,
                status: item['status']?.toString() ?? 'berlangsung',
                note: item['note']?.toString(),
              ));
              restoredSavings++;
            }
          }
        }
        // Pulihkan Gemini API Key jika ada di server
        final serverApiKey = serverData['gemini_api_key']?.toString().trim();
        if (serverApiKey != null && serverApiKey.isNotEmpty && localApiKey.isEmpty) {
          await GeminiService.saveApiKey(serverApiKey);
        }
      }

      return {
        'status': 'success',
        'message': 'Sinkronisasi berhasil! Data aman di database phpMyAdmin.',
        'pushed_new': resData['pushed_new'] ?? {},
        'restored_to_local': {
          'transactions': restoredTxs,
          'debts': restoredDebts,
          'savings': restoredSavings,
        }
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal sinkronisasi: $e'};
    }
  }
}
