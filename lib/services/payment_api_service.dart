import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentApiService {
  final String baseUrl;

  PaymentApiService({required this.baseUrl});

  Future<Map<String, dynamic>> getPaymentMeta() async {
    final uri = Uri.parse('$baseUrl/payment/meta');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw Exception('GET payment meta failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> createOrder({
    required String token,
    required String drinkName,
    required String drinkPrice,
    required String drinkImage,
    required int qty,
    required String address,
  }) async {
    final uri = Uri.parse('$baseUrl/orders');

    final body = {
      "drink_name": drinkName,
      "drink_image": drinkImage,
      "drink_price": drinkPrice,
      "qty": qty,
      "address": address,

      // COD ONLY
      "payment_method": "COD",
    };

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST order failed: ${res.statusCode} ${res.body}');
    }
  }
}
