import 'package:flutter/material.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Text(
          'Настройки будут доступны позже',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
