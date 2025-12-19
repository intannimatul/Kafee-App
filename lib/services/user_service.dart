import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print('UserService: token kosong');
        return null;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService ME status: ${res.statusCode}');
      print('UserService ME body: ${res.body}');

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);

      if (data is Map<String, dynamic>) {
        if (data['name'] != null) return data['name'].toString();
        if (data['user']?['name'] != null) {
          return data['user']['name'].toString();
        }
        if (data['data']?['name'] != null) {
          return data['data']['name'].toString();
        }
      }

      return null;
    } catch (e) {
      print('UserService ERROR: $e');
      return null;
    }
  }
}
