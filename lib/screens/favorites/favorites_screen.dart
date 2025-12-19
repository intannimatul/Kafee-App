import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/top_menu_button.dart';

import '../home/home_screen.dart';
import '../detail/drink_menu_screen.dart';
import '../orders/orders_screen.dart';

import '../../services/favorites_api_service.dart';

class FavoriteDrink {
  final int drinkId;
  final String name;
  final String price;
  final String imagePath;

  FavoriteDrink({
    required this.drinkId,
    required this.name,
    required this.price,
    required this.imagePath,
  });

  factory FavoriteDrink.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return FavoriteDrink(
      drinkId: toInt(j['drink_id'] ?? j['drinkId'] ?? j['id']),
      name: (j['name'] ?? j['drink_name'] ?? '-')?.toString() ?? '-',
      price: (j['price'] ?? j['drink_price'] ?? '-')?.toString() ?? '-',
      imagePath:
          (j['imagePath'] ??
                  j['image_path'] ??
                  j['drink_image'] ??
                  j['drinkImage'] ??
                  '')
              .toString(),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final int _currentIndex = 3;
  final _api = FavoritesApiService(baseUrl: 'http://10.0.2.2:8000/api');

  bool _loading = true;
  bool _mutating = false;
  String? _error;

  List<FavoriteDrink> _favorites = [];

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token kosong. Login dulu ya.');
      }

      final data = await _api.getFavorites(token: token);
      final items = data.map((e) => FavoriteDrink.fromJson(e)).toList();

      setState(() {
        _favorites = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeFavorite(int drinkId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      setState(() => _mutating = true);
      await _api.removeFavorite(token: token, drinkId: drinkId);
      await _loadFavorites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal hapus favorite: $e')));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
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
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    }
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
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Your favorite drinks to\nlighten up your day',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _loadFavorites,
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                  ),
                  const TopMenuButton(),
                ],
              ),
            ),

            const SizedBox(height: 8),

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
                              onPressed: _loadFavorites,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_favorites.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada favorit.',
                        style: TextStyle(
                          color: AppColors.textDark.withOpacity(0.7),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: _favorites.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.80,
                          ),
                      itemBuilder: (context, index) {
                        final drink = _favorites[index];
                        return _FavoriteAestheticCard(
                          drink: drink,
                          disabled: _mutating,
                          onRemove: () => _removeFavorite(drink.drinkId),
                        );
                      },
                    ),
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

/// ===== FAVORITE CARD (AESTHETIC) =====
class _FavoriteAestheticCard extends StatelessWidget {
  final FavoriteDrink drink;
  final VoidCallback onRemove;
  final bool disabled;

  const _FavoriteAestheticCard({
    required this.drink,
    required this.onRemove,
    required this.disabled,
  });

  String _resolveAssetPath(String raw) {
    if (raw.trim().isEmpty) return 'assets/images/drinks/default.jpeg';
    if (raw.startsWith('assets/')) return raw;
    // kalau backend ngirim "iced_americano.jpeg"
    return 'assets/images/drinks/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = _resolveAssetPath(drink.imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/drinks/default.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // soft dark overlay biar text kebaca
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          // Text bottom
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drink.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        drink.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: disabled ? null : onRemove,
                      child: Opacity(
                        opacity: disabled ? 0.5 : 1,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
