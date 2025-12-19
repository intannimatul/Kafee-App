import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/top_menu_button.dart';

import '../home/home_screen.dart';
import '../orders/orders_screen.dart';
import '../favorites/favorites_screen.dart';
import '../payment/payment_screen.dart';

import '../../services/api_service.dart';
import '../../models/drink.dart';

import '../../services/favorites_api_service.dart';

enum DrinkCategory { coffee, chocolate, others }

class DrinkItem {
  final int id;
  final String name;
  final String description;
  final String price;
  final String imagePath;
  final DrinkCategory category;

  DrinkItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.category,
  });
}

DrinkCategory _mapCategory(String category) {
  final c = category.toLowerCase().trim();
  if (c == 'coffee') return DrinkCategory.coffee;
  if (c == 'chocolate') return DrinkCategory.chocolate;
  return DrinkCategory.others;
}

String _formatRupiah(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final posFromEnd = s.length - i - 1;
    if (posFromEnd > 0 && posFromEnd % 3 == 0) buf.write('.');
  }
  return 'Rp ${buf.toString()}';
}

class DrinkMenuScreen extends StatefulWidget {
  const DrinkMenuScreen({super.key});

  @override
  State<DrinkMenuScreen> createState() => _DrinkMenuScreenState();
}

class _DrinkMenuScreenState extends State<DrinkMenuScreen> {
  DrinkCategory _selectedCategory = DrinkCategory.coffee;
  String _searchText = '';

  final ApiService _api = ApiService();
  late Future<List<Drink>> _futureDrinks;

  @override
  void initState() {
    super.initState();
    _futureDrinks = _api.getDrinks();
  }

  List<DrinkItem> _filteredFromApi(List<Drink> apiDrinks) {
    final items = apiDrinks.map((d) {
      return DrinkItem(
        id: d.id, // Drink model punya id
        name: d.name,
        description: d.description,
        price: _formatRupiah(d.price),
        imagePath: 'assets/images/drinks/${d.imagePath}',
        category: _mapCategory(d.category),
      );
    }).toList();

    return items.where((item) {
      final matchCategory = item.category == _selectedCategory;
      final matchSearch = item.name.toLowerCase().contains(
        _searchText.toLowerCase(),
      );
      return matchCategory && matchSearch;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == 1) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  void _changeCategory(DrinkCategory category) {
    setState(() => _selectedCategory = category);
  }

  void _refresh() {
    setState(() {
      _futureDrinks = _api.getDrinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: KafeeBottomNavBar(currentIndex: 1, onTap: _onNavTap),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      "What would you\nlike to drink today?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: AppColors.primary,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _refresh,
                  ),
                  const TopMenuButton(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchText = v),
                decoration: InputDecoration(
                  hintText: "Search..",
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    _CategoryTab(
                      text: "Coffee",
                      isActive: _selectedCategory == DrinkCategory.coffee,
                      onTap: () => _changeCategory(DrinkCategory.coffee),
                    ),
                    _CategoryTab(
                      text: "Chocolate",
                      isActive: _selectedCategory == DrinkCategory.chocolate,
                      onTap: () => _changeCategory(DrinkCategory.chocolate),
                    ),
                    _CategoryTab(
                      text: "Others",
                      isActive: _selectedCategory == DrinkCategory.others,
                      onTap: () => _changeCategory(DrinkCategory.others),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FutureBuilder<List<Drink>>(
                  future: _futureDrinks,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final filtered = _filteredFromApi(snapshot.data ?? []);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('Data minuman kosong'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        return _DrinkTile(drink: filtered[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
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
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.textLight : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrinkTile extends StatelessWidget {
  final DrinkItem drink;

  const _DrinkTile({required this.drink});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DrinkDetailSheet(drink: drink),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          drink.imagePath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported),
          ),
        ),
      ),
      title: Text(
        drink.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(drink.description, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            drink.price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: AppColors.textLight, size: 18),
          onPressed: () => _openDetail(context),
        ),
      ),
    );
  }
}

class _DrinkDetailSheet extends StatefulWidget {
  final DrinkItem drink;

  const _DrinkDetailSheet({required this.drink});

  @override
  State<_DrinkDetailSheet> createState() => _DrinkDetailSheetState();
}

class _DrinkDetailSheetState extends State<_DrinkDetailSheet> {
  int _qty = 1;
  bool _savingFav = false;

  final _favApi = FavoritesApiService(baseUrl: 'http://10.0.2.2:8000/api');

  void _inc() => setState(() => _qty++);
  void _dec() {
    if (_qty > 1) setState(() => _qty--);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _showSavedToFavoritesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content: const Text(
            'Saved to Favorites',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToFavorites() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token kosong. Login dulu ya.')),
      );
      return;
    }

    try {
      setState(() => _savingFav = true);
      await _favApi.addFavorite(token: token, drinkId: widget.drink.id);

      if (!mounted) return;
      _showSavedToFavoritesDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal favorite: $e')));
    } finally {
      if (mounted) setState(() => _savingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drink = widget.drink;
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.9,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                drink.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, size: 60),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _savingFav ? null : _addToFavorites, // ✅ POST API
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      drink.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      drink.description,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      drink.price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _dec,
                              ),
                              Text(
                                '$_qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: _inc,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentScreen(
                                  drinkName: drink.name,
                                  drinkPrice: drink.price,
                                  drinkImagePath: drink.imagePath,
                                  qty: _qty,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
