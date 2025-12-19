import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../../services/payment_api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String drinkName;
  final String drinkPrice;
  final String drinkImagePath;
  final int qty;

  const PaymentScreen({
    super.key,
    required this.drinkName,
    required this.drinkPrice,
    required this.drinkImagePath,
    required this.qty,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const String _addrKey = 'saved_address';

  static const int _flatDeliveryFee = 3000;

  String _addressText = 'No saved address';

  final _api = PaymentApiService(baseUrl: 'http://10.0.2.2:8000/api');

  bool _loading = true;
  bool _paying = false;
  String? _error;
  Map<String, dynamic>? _meta;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _loadMeta();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_addrKey);
      if (!mounted) return;
      if (saved != null && saved.trim().isNotEmpty) {
        setState(() => _addressText = saved.trim());
      }
    } catch (_) {
      // aman
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadMeta() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final meta = await _api.getPaymentMeta();

      setState(() {
        _meta = meta;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    final s = v.toString();
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatRupiah(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
    }
    return 'Rp ${buf.toString()}';
  }

  void _openEditAddressDialog() {
    const defaultAddress = '';

    final controller = TextEditingController(
      text: _addressText == 'No saved address' ? defaultAddress : _addressText,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 80,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: AppColors.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Street, district, city (example: Jl. ...)',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        final text = controller.text.trim().isEmpty
                            ? 'No saved address'
                            : controller.text.trim();

                        final prefs = await SharedPreferences.getInstance();
                        if (text != 'No saved address') {
                          await prefs.setString(_addrKey, text);
                        } else {
                          await prefs.remove(_addrKey);
                        }

                        if (!mounted) return;
                        setState(() => _addressText = text);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePay() async {
    if (_addressText == 'No saved address') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi alamat dulu ya')));
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token kosong. Login dulu ya.')),
      );
      return;
    }

    try {
      setState(() => _paying = true);

      await _api.createOrder(
        token: token,
        drinkName: widget.drinkName,
        drinkPrice: widget.drinkPrice,
        drinkImage: widget.drinkImagePath,
        qty: widget.qty,
        address: _addressText,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Yeay!', textAlign: TextAlign.center),
          content: const Text(
            'Your order has been placed.\nPayment method: COD (Cash on Delivery).\nPlease prepare cash when the drink arrives.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal bayar: $e')));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drinkName = widget.drinkName;
    final drinkPriceStr = widget.drinkPrice;
    final qty = widget.qty;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadMeta,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final closest = (_meta?['closest_cafe'] ?? {}) as Map<String, dynamic>;
    final recs = (_meta?['recommendations'] ?? []) as List;
    final fees = (_meta?['fees'] ?? {}) as Map<String, dynamic>;

    final unitPrice = _parseMoney(drinkPriceStr);
    final subtotal = unitPrice * qty;

    // ✅ FLAT delivery fee
    final deliveryFee = _flatDeliveryFee;

    final packagingFee = _parseMoney(fees['packaging_fee']);

    final total = subtotal + deliveryFee + packagingFee;
    final safeTotal = total < 0 ? 0 : total;

    final deliverDisplay = (_addressText == 'No saved address')
        ? 'Tap Edit to add address'
        : _addressText;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Outlet:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${closest['name'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${closest['address'] ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      thickness: 1,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),

                    // Deliver to
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deliver to:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deliverDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _openEditAddressDialog,
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(height: 8, color: AppColors.primary),
                    const SizedBox(height: 16),

                    // Your order
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your order:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${qty}x  $drinkName',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(unitPrice),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      thickness: 1,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),

                    // Recommendations
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Other drinks we recommend',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final d = recs[i] as Map<String, dynamic>;
                          return _RecommendCard(
                            imagePath: (d['imagePath'] ?? '').toString(),
                            title: (d['title'] ?? '-').toString(),
                            price: (d['price'] ?? '-').toString(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fees
                    _PriceRow(
                      label: 'Subtotal',
                      value: _formatRupiah(subtotal),
                    ),
                    const SizedBox(height: 4),
                    _PriceRow(
                      label: 'Delivery fee',
                      value: _formatRupiah(deliveryFee),
                    ),
                    const SizedBox(height: 4),
                    _PriceRow(
                      label: 'Packaging fee',
                      value: _formatRupiah(packagingFee),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 8),
                    _PriceRow(
                      label: 'TOTAL',
                      value: _formatRupiah(safeTotal),
                      isBold: true,
                    ),

                    const SizedBox(height: 16),
                    Container(height: 8, color: AppColors.primary),
                    const SizedBox(height: 16),

                    // COD ONLY
                    const Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cash on Delivery (COD)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pay after your drink arrives at your address.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDark.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: null,
                          child: const Text(
                            'COD',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _paying ? null : _handlePay,
                      child: Text(
                        _paying ? 'Processing...' : 'Proceed Payment',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 13 : 12,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.textDark,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;

  const _RecommendCard({
    required this.imagePath,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            imagePath.isNotEmpty
                ? Image.asset(
                    imagePath,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.black12,
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
