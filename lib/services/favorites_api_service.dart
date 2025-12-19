import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesApiService {
  final String baseUrl;
  FavoritesApiService({required this.baseUrl});

  Future<void> addFavorite({
    required String token,
    required int drinkId,
  }) async {
    final uri = Uri.parse('$baseUrl/favorites');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'drink_id': drinkId}),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST favorite failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/favorites');
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('GET favorites failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final List data = (decoded['data'] ?? []) as List;
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<void> removeFavorite({
    required String token,
    required int drinkId,
  }) async {
    final uri = Uri.parse('$baseUrl/favorites/$drinkId');
    final res = await http.delete(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('DELETE favorite failed: ${res.statusCode} ${res.body}');
    }
  }
}
