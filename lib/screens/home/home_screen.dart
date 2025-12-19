import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/top_menu_button.dart';

import '../detail/drink_menu_screen.dart';
import '../orders/orders_screen.dart';
import '../favorites/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;

  String _userName = 'Guest';

  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  bool _homeMetaLoaded = false;

  String _bestTitle = 'Iced Coffee Sweet Heaven';
  String _bestImagePath = 'assets/images/best_seller.jpeg';

  List<Map<String, String>> _topRecs = [
    {
      'title': 'Iced Americano',
      'price': 'Rp 20.000',
      'imagePath': 'assets/images/iced_americano.jpeg',
    },
    {
      'title': 'Hot Cappuccino',
      'price': 'Rp 24.000',
      'imagePath': 'assets/images/hot_cappuccino.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchHomeMeta();
  }

  String _toDrinkAsset(
    String p, {
    String fallback = 'assets/images/best_seller.jpeg',
  }) {
    final s = p.trim();
    if (s.isEmpty) return fallback;

    if (s.startsWith('assets/')) return s;

    if (s.startsWith('images/')) return 'assets/$s';

    return 'assets/images/drinks/$s';
  }

  // USERNAME
  Future<void> _fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        debugPrint('TOKEN NULL/EMPTY => Guest');
        if (!mounted) return;
        setState(() => _userName = 'Guest');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ME status: ${response.statusCode}');
      debugPrint('ME body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final name = (data is Map)
            ? (data['name'] ?? data['user']?['name'])
            : null;

        setState(() {
          _userName = (name == null || name.toString().isEmpty)
              ? 'Guest'
              : name.toString();
        });
      } else {
        setState(() => _userName = 'Guest');
      }
    } catch (e) {
      debugPrint('ERROR fetch user: $e');
      if (!mounted) return;
      setState(() => _userName = 'Guest');
    }
  }

  String _pickString(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _pickImagePath(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;
    return s;
  }

  String _pickPrice(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;

    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty && digits.length == s.length) {
      return 'Rp $digits';
    }
    return s;
  }

  Future<void> _fetchHomeMeta() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/home/meta'),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('HOME META status: ${res.statusCode}');
      debugPrint('HOME META body: ${res.body}');

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() => _homeMetaLoaded = true);
        return;
      }

      final data = jsonDecode(res.body);
      if (data is! Map) {
        if (!mounted) return;
        setState(() => _homeMetaLoaded = true);
        return;
      }

      final best = (data['best_seller'] ?? {}) as Map;
      final recs = (data['recommendations'] ?? []) as List;

      // best seller (top #1)
      final bestTitle = _pickString(best['title'] ?? best['name'], _bestTitle);
      final bestImageRaw = _pickImagePath(
        best['imagePath'] ?? best['image_path'] ?? best['drink_image'],
        _bestImagePath,
      );

      // recommendations (top #2 dan #3)
      final List<Map<String, String>> top2 = [];
      for (int i = 0; i < recs.length && top2.length < 2; i++) {
        final item = recs[i];
        if (item is! Map) continue;

        final title = _pickString(item['title'] ?? item['name'], '');
        if (title.isEmpty) continue;

        final imgRaw = _pickImagePath(
          item['imagePath'] ?? item['image_path'] ?? item['drink_image'],
          '',
        );

        top2.add({
          'title': title,
          'price': _pickPrice(item['price'] ?? item['drink_price'], 'Rp 0'),
          'imagePath': imgRaw,
        });
      }

      if (!mounted) return;
      setState(() {
        _bestTitle = bestTitle;
        _bestImagePath = _toDrinkAsset(
          bestImageRaw,
          fallback: 'assets/images/best_seller.jpeg',
        );

        if (top2.length == 2) {
          _topRecs = top2
              .map(
                (d) => {
                  'title': d['title'] ?? '-',
                  'price': d['price'] ?? 'Rp 0',
                  'imagePath': _toDrinkAsset(
                    (d['imagePath'] ?? '').toString(),
                    fallback: 'assets/images/best_seller.jpeg',
                  ),
                },
              )
              .toList();
        }

        _homeMetaLoaded = true;
      });
    } catch (e) {
      debugPrint('ERROR fetch home meta: $e');
      if (!mounted) return;
      setState(() => _homeMetaLoaded = true);
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DrinkMenuScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER: GREETING + ICONS =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Good day, $_userName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: AppColors.primary,
                    ),
                    onPressed: () {},
                  ),
                  const TopMenuButton(),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Best seller of the week',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _bestTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'More info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_right_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        _bestImagePath,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Image.asset(
                            'assets/images/best_seller.jpeg',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                title: "This week's recommendations",
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _topRecs.map((d) {
                    return _DrinkRecommendationCard(
                      title: d['title'] ?? '-',
                      price: d['price'] ?? 'Rp 0',
                      imagePath:
                          d['imagePath'] ?? 'assets/images/best_seller.jpeg',
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "What's in the shop?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/shop_banner.jpeg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Introducing our\nnew lemonade\nmenu',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Try our refreshing lemonade, strawberry\nlemonade, and orange lemonade',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _SectionHeader(title: 'A few words from us', onSeeAll: () {}),
              const SizedBox(height: 12),

              Row(
                children: const [
                  Expanded(
                    child: _ArticleCard(
                      title: 'Why Kafee?',
                      subtitle:
                          'Since 2024, Kafee provides you with our best coffee or chocolate...',
                      imagePath: 'assets/images/article1.jpeg',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ArticleCard(
                      title: 'Benefits of coffee',
                      subtitle:
                          'Coffee is one of the most consumed drinks in the world...',
                      imagePath: 'assets/images/article2.jpeg',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (!_homeMetaLoaded) const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: KafeeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: TextStyle(fontSize: 13, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DrinkRecommendationCard extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;

  const _DrinkRecommendationCard({
    required this.title,
    required this.price,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Image.asset(
                    'assets/images/best_seller.jpeg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(price, style: TextStyle(fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const _ArticleCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            height: 110,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Read more',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
