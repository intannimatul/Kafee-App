import 'dart:convert';
import 'package:http/http.dart' as http;

class OrdersApiService {
  final String baseUrl;
  final String token;

  OrdersApiService({required this.baseUrl, required this.token});

  Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed load orders');
    }

    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }
}
