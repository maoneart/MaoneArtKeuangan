import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/saving_model.dart';
import '../models/category_model.dart';
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

  static Future<List<String>> getCandidateUrls([String? currentBase]) async {
    final list = <String>[];
    if (currentBase != null && currentBase.trim().isNotEmpty) {
      list.add(normalizeUrl(currentBase));
    } else {
      final saved = await getServerUrl();
      list.add(saved);
    }

    // 1. Tambahkan loopback & host emulator
    list.add('http://127.0.0.1:8085/Keuangan/api');
    list.add('http://localhost:8085/Keuangan/api');
    list.add('http://10.0.2.2:8085/Keuangan/api');
    list.add('http://127.0.0.1:8081/Keuangan/api');
    list.add('http://localhost:8081/Keuangan/api');

    // 2. Deteksi semua IP jaringan perangkat (Wi-Fi, hotspot, LAN)
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address.trim();
          if (ip.isNotEmpty && ip != '127.0.0.1') {
            list.add('http://$ip:8085/Keuangan/api');
            list.add('http://$ip:8081/Keuangan/api');
          }
        }
      }
    } catch (_) {}

    return list.toSet().toList();
  }

  // Cek Status Server phpMyAdmin & Database db_keuangan
  static Future<Map<String, dynamic>> checkStatus([String? customUrl]) async {
    final base = customUrl != null && customUrl.trim().isNotEmpty
        ? normalizeUrl(customUrl)
        : await getServerUrl();

    final candidates = await getCandidateUrls(base);
    String lastErr = 'Tidak dapat terhubung';

    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/status.php');
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (cand != base) {
            await saveServerUrl(cand);
          }
          return data;
        } else {
          lastErr = 'HTTP ${res.statusCode}';
        }
      } catch (e) {
        lastErr = '$e';
      }
    }

    return {'status': 'error', 'message': 'Tidak dapat terhubung ke server ($lastErr)'};
  }

  // Kirim transaksi baru ke phpMyAdmin secara real-time
  static Future<bool> pushTransaction(TransactionModel tx) async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    final body = jsonEncode({
      'date': tx.date.toIso8601String(),
      'type': tx.type,
      'categoryId': tx.categoryId,
      'amount': tx.amount,
      'note': tx.note ?? '',
    });

    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/transaksi.php');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200 || res.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Ambil Gemini API Key dari phpMyAdmin (app_settings)
  static Future<String?> fetchGeminiApiKey() async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/settings.php?key=gemini_api_key');
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final key = data['key_value']?.toString().trim();
          if (key != null && key.isNotEmpty) {
            await GeminiService.saveApiKey(key);
            return key;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // Simpan Gemini API Key ke phpMyAdmin (app_settings)
  static Future<bool> saveGeminiApiKey(String apiKey) async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    final body = jsonEncode({
      'key_name': 'gemini_api_key',
      'key_value': apiKey.trim(),
    });

    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/settings.php');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Hapus transaksi dari phpMyAdmin secara real-time
  static Future<bool> deleteTransactionRemote(int id) async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/transaksi.php?id=$id');
        final res = await http.delete(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Tambah / Simpan Kategori ke phpMyAdmin secara real-time
  static Future<bool> pushCategoryRemote(CategoryModel cat) async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    final body = jsonEncode({
      'name': cat.name,
      'type': cat.type,
      'icon': cat.iconName,
      'color': cat.colorHex,
    });

    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/kategori.php');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200 || res.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Hapus Kategori dari phpMyAdmin secara real-time
  static Future<bool> deleteCategoryRemote(int id, {String? name, String? type}) async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    for (final cand in candidates) {
      try {
        var uriStr = '$cand/kategori.php?id=$id';
        if (name != null && name.isNotEmpty) {
          uriStr += '&name=${Uri.encodeComponent(name)}';
        }
        if (type != null && type.isNotEmpty) {
          uriStr += '&type=${Uri.encodeComponent(type)}';
        }
        final url = Uri.parse(uriStr);
        final res = await http.delete(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Reset Data di phpMyAdmin (MySQL)
  static Future<bool> resetRemoteData() async {
    final base = await getServerUrl();
    final candidates = await getCandidateUrls(base);
    for (final cand in candidates) {
      try {
        final url = Uri.parse('$cand/reset.php');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // Sinkronisasi Penuh 2 Arah (Full Bidirectional Sync)
  static Future<Map<String, dynamic>> syncFull(DatabaseHelper db) async {
    try {
      final base = await getServerUrl();
      final candidates = await getCandidateUrls(base);

      // 1. Ambil data lokal SQLite & API Key
      final localTxs = await db.getTransactions(limit: 1000);
      final localDebts = await db.getDebts();
      final localSavings = await db.getSavings();
      final localCategories = await db.getCategories();
      final localApiKey = await GeminiService.getApiKey() ?? '';

      // 2. Buat Payload Lengkap
      final payload = {
        'gemini_api_key': localApiKey,
        'categories': localCategories.map((c) => {
          'id': c.id,
          'name': c.name,
          'type': c.type,
          'icon': c.iconName,
          'color': c.colorHex,
        }).toList(),
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
          'categoryDebt': d.categoryDebt,
          'totalAmount': d.totalAmount,
          'remainingAmount': d.remainingAmount,
          'status': d.status,
          'borrowDate': d.borrowDate.toIso8601String(),
          'dueDate': d.dueDate?.toIso8601String(),
          'tenorMonths': d.tenorMonths,
          'dueDay': d.dueDay,
          'monthlyInstallment': d.monthlyInstallment,
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

      http.Response? response;
      String? workingBase;

      // Coba kirim ke candidate URLs
      for (final cand in candidates) {
        try {
          final url = Uri.parse('$cand/sync.php');
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200) {
            response = res;
            workingBase = cand;
            break;
          }
        } catch (_) {}
      }

      if (response == null || response.statusCode != 200) {
        return {'status': 'error', 'message': 'Tidak dapat terhubung ke server Apache / PHP Termux di port 8085 / 8081'};
      }

      if (workingBase != null && workingBase != base) {
        await saveServerUrl(workingBase);
      }

      final resData = jsonDecode(response.body);
      final serverData = resData['data'] as Map<String, dynamic>?;

      int restoredTxs = 0;
      int restoredDebts = 0;
      int restoredSavings = 0;

      // 4. Sinkronkan Master Penuh dari phpMyAdmin ke SQLite lokal
      if (serverData != null) {
        final serverTxs = serverData['transactions'] as List? ?? [];
        final serverDebts = serverData['debts'] as List? ?? [];
        final serverSavings = serverData['savings'] as List? ?? [];
        final serverCats = serverData['categories'] as List? ?? [];

        await db.syncMasterFromServer(
          serverTransactions: serverTxs,
          serverDebts: serverDebts,
          serverSavings: serverSavings,
          serverCategories: serverCats,
        );

        restoredTxs = serverTxs.length;
        restoredDebts = serverDebts.length;
        restoredSavings = serverSavings.length;

        // Pulihkan Gemini API Key jika ada di server
        final serverApiKey = serverData['gemini_api_key']?.toString().trim();
        if (serverApiKey != null && serverApiKey.isNotEmpty && localApiKey.isEmpty) {
          await GeminiService.saveApiKey(serverApiKey);
        }
      }

      return {
        'status': 'success',
        'message': 'Sinkronisasi berhasil! Data aman dan identik dengan database phpMyAdmin.',
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
