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

      // 4. Pulihkan data dari phpMyAdmin ke SQLite lokal jika belum ada di lokal
      if (serverData != null) {
        // Transaksi
        final serverTxs = serverData['transactions'] as List? ?? [];
        for (final item in serverTxs) {
          if (item is Map<String, dynamic>) {
            final tglStr = item['date']?.toString() ?? '';
            final tgl = DateTime.tryParse(tglStr) ?? DateTime.now();
            final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            final note = (item['note']?.toString() ?? '').trim();
            final type = item['type']?.toString() ?? 'pengeluaran';
            final catId = int.tryParse(item['categoryId']?.toString() ?? '1') ?? 1;

            if (amt <= 0) continue;

            final exists = await db.transactionExists(date: tgl, amount: amt, note: note);

            if (!exists) {
              await db.insertTransaction(TransactionModel(
                date: tgl,
                type: type,
                categoryId: catId,
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
            final name = (item['debtorName']?.toString() ?? 'Rekan').trim();
            final amt = double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0.0;

            if (amt <= 0) continue;

            final exists = await db.debtExists(debtorName: name, totalAmount: amt);
            if (!exists) {
              final tgl = DateTime.tryParse(item['borrowDate']?.toString() ?? '') ?? DateTime.now();
              await db.insertDebt(DebtModel(
                debtorName: name,
                type: item['type']?.toString() ?? 'hutang',
                categoryDebt: item['categoryDebt']?.toString() ?? 'Perorangan / Teman',
                totalAmount: amt,
                remainingAmount: double.tryParse(item['remainingAmount']?.toString() ?? '0') ?? amt,
                status: item['status']?.toString() ?? 'belum_lunas',
                borrowDate: tgl,
                dueDate: DateTime.tryParse(item['dueDate']?.toString() ?? ''),
                tenorMonths: int.tryParse(item['tenorMonths']?.toString() ?? '0') ?? 0,
                dueDay: int.tryParse(item['dueDay']?.toString() ?? '0') ?? 0,
                monthlyInstallment: double.tryParse(item['monthlyInstallment']?.toString() ?? '0') ?? 0.0,
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
            final name = (item['name']?.toString() ?? 'Tabungan').trim();
            final target = double.tryParse(item['targetAmount']?.toString() ?? '0') ?? 0.0;

            if (name.isEmpty || target <= 0) continue;

            final exists = await db.savingExists(name: name);
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

        // Kategori
        final serverCats = serverData['categories'] as List? ?? [];
        for (final item in serverCats) {
          if (item is Map<String, dynamic>) {
            final name = (item['name']?.toString() ?? item['nama_kategori']?.toString() ?? '').trim();
            final type = item['type']?.toString() ?? item['tipe']?.toString() ?? 'pengeluaran';
            final icon = item['icon']?.toString() ?? item['ikon']?.toString() ?? 'bi-bookmark';
            final color = item['color']?.toString() ?? item['warna']?.toString() ?? '#10B981';

            if (name.isEmpty) continue;

            final exists = await db.categoryExists(name: name, type: type);
            if (!exists) {
              await db.insertCategory(CategoryModel(
                name: name,
                type: type,
                iconName: icon,
                colorHex: color,
              ));
            }
          }
        }

        // Bersihkan duplikat lokal jika sempat terjadi
        await db.removeDuplicateTransactions();

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
