import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminDrinkService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/admin/drinks';

  // GET - ambil semua drinks
  Future<List<dynamic>> fetchDrinks() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong, belum login');
    }

    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception('Gagal ambil drinks (${res.statusCode}): ${res.body}');
  }

  // POST - tambah drink
  Future<void> createDrink({
    required String name,
    required int price,
    required String category,
    String? description,
    String? imagePath,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong, belum login');
    }

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'category': category,
        'description': description ?? '',
        'image_path': imagePath ?? '',
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) return;

    throw Exception('Gagal tambah drink (${res.statusCode}): ${res.body}');
  }

  // PUT - update drink
  Future<void> updateDrink({
    required int id,
    required String name,
    required int price,
    required String category,
    String? description,
    String? imagePath,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong, belum login');
    }

    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'category': category,
        'description': description ?? '',
        'image_path': imagePath ?? '',
      }),
    );

    if (res.statusCode == 200) return;

    throw Exception('Gagal update drink (${res.statusCode}): ${res.body}');
  }

  // DELETE - hapus drink
  Future<void> deleteDrink(int id) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong, belum login');
    }

    final res = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) return;

    throw Exception('Gagal hapus drink (${res.statusCode}): ${res.body}');
  }
}
