import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.100.35:8000';
  static const String apiBase = '$baseUrl/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ✅ tambahan: simpan role
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
  }

  Map<String, String> _jsonHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _safeJsonDecode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('JSON bukan object/map. Body: ${res.body}');
    } catch (_) {
      throw Exception(
        'Server tidak mengirim JSON. Cek URL/route atau server error.\nBody: ${res.body}',
      );
    }
  }

  String _pickMessage(
    Map<String, dynamic> data, {
    String fallback = 'Request gagal',
  }) {
    final msg = data['message'] ?? data['error'] ?? data['errors'];
    if (msg == null) return fallback;

    if (msg is Map) {
      try {
        final firstKey = msg.keys.first;
        final firstVal = msg[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          return firstVal.first.toString();
        }
        return msg.toString();
      } catch (_) {
        return msg.toString();
      }
    }

    return msg.toString();
  }

  String? _extractToken(Map<String, dynamic> data) {
    final candidates = [
      data['token'],
      data['access_token'],
      data['data']?['token'],
      data['data']?['access_token'],
    ];

    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    return null;
  }

  String _extractRole(Map<String, dynamic> data) {
    final roleCandidates = [
      data['user']?['role'],
      data['data']?['user']?['role'],
      data['role'],
      data['data']?['role'],
    ];

    for (final c in roleCandidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    return 'user';
  }

  /// ✅ REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBase/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = _safeJsonDecode(res);

    print('REGISTER status: ${res.statusCode}');
    print('REGISTER body: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data;
    }

    throw Exception(_pickMessage(data));
  }

  /// LOGIN: simpan token + simpan role
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBase/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _safeJsonDecode(res);

    print('LOGIN status: ${res.statusCode}');
    print('LOGIN body: ${res.body}');

    if (res.statusCode == 200) {
      final token = _extractToken(data);
      if (token == null || token.isEmpty) {
        throw Exception(
          'Login sukses tapi token kosong. Cek response backend.',
        );
      }

      await saveToken(token);

      // simpan role
      final role = _extractRole(data);
      await saveRole(role);

      return data;
    }

    // email belum verifikasi (sesuai backend)
    if (res.statusCode == 403) {
      throw Exception(
        _pickMessage(data, fallback: 'Email belum diverifikasi.'),
      );
    }

    throw Exception(_pickMessage(data));
  }

  Future<Map<String, dynamic>> me() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong, belum login');
    }

    final res = await http.get(
      Uri.parse('$apiBase/me'),
      headers: _jsonHeaders(token: token),
    );

    final data = _safeJsonDecode(res);

    print('ME status: ${res.statusCode}');
    print('ME body: ${res.body}');

    if (res.statusCode == 200) {
      final role = _extractRole(data);
      await saveRole(role);
      return data;
    }

    throw Exception(_pickMessage(data));
  }

  Future<void> logout() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await clearToken();
      await clearRole();
      return;
    }

    await http.post(
      Uri.parse('$apiBase/logout'),
      headers: _jsonHeaders(token: token),
    );

    await clearToken();
    await clearRole();
  }
}
