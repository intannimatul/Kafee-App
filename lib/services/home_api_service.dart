import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeApiService {
  final String baseUrl;
  HomeApiService({required this.baseUrl});

  Future<Map<String, dynamic>> getHomeMeta() async {
    final uri = Uri.parse('$baseUrl/home/meta');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Invalid response shape');
    }

    throw Exception('GET home meta failed: ${res.statusCode} ${res.body}');
  }
}
