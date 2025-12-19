import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome/welcome_screen.dart';

void main() {
  runApp(const KafeeApp());
}

class KafeeApp extends StatelessWidget {
  const KafeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAFEE',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WelcomeScreen(),
    );
  }
}
