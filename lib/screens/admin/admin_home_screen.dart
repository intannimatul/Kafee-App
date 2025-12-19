import 'package:flutter/material.dart';
import 'admin_manage_drinks_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_cafe),
              title: const Text('Manage Drinks'),
              subtitle: const Text('Tambah, edit, hapus menu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminManageDrinksScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
