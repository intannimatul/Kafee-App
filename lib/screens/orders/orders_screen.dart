import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/top_menu_button.dart';

import '../home/home_screen.dart';
import '../detail/drink_menu_screen.dart';
import '../favorites/favorites_screen.dart';

class OrderItem {
  final String name;
  final int qty;
  final DateTime createdAt;
  final String imagePath;

  OrderItem({
    required this.name,
    required this.qty,
    required this.createdAt,
    required this.imagePath,
  });

  bool get isRecent {
    final now = DateTime.now();
    final diff = now.difference(createdAt).inDays;
    return diff <= 7; // <= 7 hari dianggap recent
  }

  String get dateText {
    final d = createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}';
  }

  String get qtyText => '${qty}x';

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    final s = v.toString();
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _pickString(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    final name = _pickString(j, [
      'drink_name',
      'drinkName',
      'name',
      'title',
    ], fallback: '-');

    final qty = _parseInt(j['qty'] ?? j['quantity'] ?? j['count'] ?? 1);

    final createdAt = _parseDate(
      j['created_at'] ?? j['createdAt'] ?? j['date'],
    );

    // image: bisa asset path atau URL/path dari backend
    final imgRaw = _pickString(j, [
      'image_path',
      'imagePath',
      'image',
      'photo',
    ], fallback: '');

    final imagePath = imgRaw.isNotEmpty
        ? imgRaw
        : 'assets/images/drinks/iced_americano.jpeg';

    return OrderItem(
      name: name,
      qty: qty,
      createdAt: createdAt,
      imagePath: imagePath,
    );
  }
}

class OrdersApiService {
  final String baseUrl;
  const OrdersApiService({required this.baseUrl});

  Future<List<OrderItem>> fetchOrders({required String token}) async {
    final uri = Uri.parse('$baseUrl/orders');
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch orders failed (${res.statusCode}): ${res.body}');
    }

    final decoded = json.decode(res.body);

    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] ?? decoded['orders'] ?? [])
        : (decoded as List);

    return list
        .whereType<dynamic>()
        .map((e) => OrderItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _tabIndex = 0;
  final int _currentIndex = 2;

  final _api = const OrdersApiService(baseUrl: 'http://10.0.2.2:8000/api');

  bool _loading = true;
  String? _error;

  List<OrderItem> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token kosong. Login dulu ya.');
      }

      final orders = await _api.fetchOrders(token: token);

      // sorting terbaru dulu
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<OrderItem> get _filteredOrders {
    final bool wantRecent = _tabIndex == 0;
    return _orders.where((o) => o.isRecent == wantRecent).toList();
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DrinkMenuScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
      );
    }
  }

  void _changeTab(int index) {
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: KafeeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Your orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadOrders, // refresh
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                  ),
                  const TopMenuButton(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _OrdersTab(
                    text: "Recently",
                    isActive: _tabIndex == 0,
                    onTap: () => _changeTab(0),
                  ),
                  const SizedBox(width: 8),
                  _OrdersTab(
                    text: "Past Orders",
                    isActive: _tabIndex == 1,
                    onTap: () => _changeTab(1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Builder(
                builder: (_) {
                  if (_loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: $_error', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = _filteredOrders;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _tabIndex == 0
                            ? 'Belum ada order terbaru.'
                            : 'Belum ada past orders.',
                        style: TextStyle(
                          color: AppColors.textDark.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _OrderCard(order: items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _OrdersTab({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.textLight : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isAsset = order.imagePath.startsWith('assets/');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isAsset
                ? Image.asset(
                    order.imagePath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/drinks/iced_americano.jpeg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.qtyText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        order.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Details',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Text(
            order.dateText,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
