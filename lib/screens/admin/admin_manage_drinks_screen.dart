import 'package:flutter/material.dart';
import '../../services/admin_drink_service.dart';

class AdminManageDrinksScreen extends StatefulWidget {
  const AdminManageDrinksScreen({super.key});

  @override
  State<AdminManageDrinksScreen> createState() =>
      _AdminManageDrinksScreenState();
}

class _AdminManageDrinksScreenState extends State<AdminManageDrinksScreen> {
  final _service = AdminDrinkService();
  late Future<List<dynamic>> _drinksFuture;

  void _reload() {
    setState(() {
      _drinksFuture = _service.fetchDrinks();
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;

    final nameC = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final priceC = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    final catC = TextEditingController(
      text: existing?['category']?.toString() ?? '',
    );
    final descC = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final imgC = TextEditingController(
      text: existing?['image_path']?.toString() ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Drink' : 'Tambah Drink'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (angka)'),
                ),
                TextField(
                  controller: catC,
                  decoration: const InputDecoration(
                    labelText: 'Category (coffee/chocolate/others)',
                  ),
                ),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: imgC,
                  decoration: const InputDecoration(
                    labelText: 'Image filename (opsional)',
                    hintText: 'contoh: iced_americano.jpeg',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final name = nameC.text.trim();
    final priceStr = priceC.text.trim();
    final category = catC.text.trim();
    final description = descC.text.trim();
    final imagePath = imgC.text.trim();

    if (name.isEmpty || priceStr.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Price, Category wajib diisi')),
      );
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Price harus angka')));
      return;
    }

    try {
      if (isEdit) {
        await _service.updateDrink(
          id: existing!['id'],
          name: name,
          price: price,
          category: category,
          description: description,
          imagePath: imagePath,
        );
      } else {
        await _service.createDrink(
          name: name,
          price: price,
          category: category,
          description: description,
          imagePath: imagePath,
        );
      }

      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Berhasil update' : 'Berhasil tambah')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteDrink(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus drink?'),
        content: const Text('Yakin mau hapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deleteDrink(id);

      if (!mounted) return;
      _reload();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil hapus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drinks'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openForm()),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _drinksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final drinks = snapshot.data ?? [];
          if (drinks.isEmpty) {
            return const Center(child: Text('Belum ada drinks'));
          }

          return ListView.builder(
            itemCount: drinks.length,
            itemBuilder: (context, index) {
              final d = drinks[index];
              final id = d['id'];

              return ListTile(
                leading: const Icon(Icons.local_cafe),
                title: Text(d['name']?.toString() ?? '-'),
                subtitle: Text('Rp ${d['price']} • ${d['category']}'),
                onTap: () => _openForm(existing: Map<String, dynamic>.from(d)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteDrink(id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
