import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drink.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<Drink>> getDrinks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/drinks'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Drink.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load drinks');
    }
  }
}
