import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'phpmyadmin_service.dart';

class AuthService {
  static const String _prefIsLoggedIn = 'auth_is_logged_in';
  static const String _prefUserId = 'auth_user_id';
  static const String _prefUserName = 'auth_user_name';
  static const String _prefUserEmail = 'auth_user_email';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefIsLoggedIn) ?? false;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_prefIsLoggedIn) ?? false)) return null;
    return {
      'id': prefs.getInt(_prefUserId) ?? 3,
      'name': prefs.getString(_prefUserName) ?? 'Hermawan',
      'email': prefs.getString(_prefUserEmail) ?? 'Maone.miui@gmail.com',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final base = await PhpMyAdminService.getServerUrl();
      final candidates = await PhpMyAdminService.getCandidateUrls(base);

      String lastError = 'Tidak dapat terhubung ke server cloud.';

      for (final cand in candidates) {
        try {
          final url = Uri.parse('$cand/login.php');
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          ).timeout(const Duration(seconds: 5));

          final data = jsonDecode(response.body) as Map<String, dynamic>;

          if (response.statusCode == 200 && data['status'] == 'success') {
            final user = data['user'] as Map<String, dynamic>;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_prefIsLoggedIn, true);
            await prefs.setInt(_prefUserId, (user['id'] as num).toInt());
            await prefs.setString(_prefUserName, user['name']?.toString() ?? 'Hermawan');
            await prefs.setString(_prefUserEmail, user['email']?.toString() ?? email);
            return {'status': 'success', 'user': user};
          } else {
            lastError = data['message'] ?? 'Email atau password salah.';
          }
        } catch (_) {}
      }

      return {'status': 'error', 'message': lastError};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsLoggedIn, false);
    await prefs.remove(_prefUserId);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefUserEmail);
  }
}
