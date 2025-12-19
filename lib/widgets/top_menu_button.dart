import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TopMenuButton extends StatelessWidget {
  final void Function(String value)? onSelected;

  const TopMenuButton({super.key, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.card,
      elevation: 4,
      icon: const Icon(Icons.menu, color: AppColors.primary),

      // onSelected
      onSelected: (value) {
        if (onSelected != null) {
          onSelected!(value);
          return;
        }

        // DEFAULT ACTION SAAT ITEM DIKLIK
        if (value == "logout") {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$value clicked")));
        }
      },

      itemBuilder: (context) => [
        _popupItem(Icons.person, "Profile", "profile"),
        _popupItem(Icons.settings, "Settings", "settings"),
        _popupItem(Icons.help_outline, "Help", "help"),
        const PopupMenuDivider(height: 0),
        _popupItem(Icons.logout, "Logout", "logout"),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
