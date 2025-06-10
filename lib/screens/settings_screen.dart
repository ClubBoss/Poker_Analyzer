import 'package:flutter/material.dart';

import '../user_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showPotAnimation;
  late bool _showCardReveal;
  late bool _showWinnerCelebration;

  @override
  void initState() {
    super.initState();
    final prefs = UserPreferences.instance;
    _showPotAnimation = prefs.showPotAnimation;
    _showCardReveal = prefs.showCardReveal;
    _showWinnerCelebration = prefs.showWinnerCelebration;
  }

  Future<void> _togglePotAnimation(bool value) async {
    setState(() => _showPotAnimation = value);
    await UserPreferences.instance.setShowPotAnimation(value);
  }

  Future<void> _toggleCardReveal(bool value) async {
    setState(() => _showCardReveal = value);
    await UserPreferences.instance.setShowCardReveal(value);
  }

  Future<void> _toggleWinnerCelebration(bool value) async {
    setState(() => _showWinnerCelebration = value);
    await UserPreferences.instance.setShowWinnerCelebration(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: _showPotAnimation,
            title: const Text('Show Pot Animation'),
            onChanged: _togglePotAnimation,
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            value: _showCardReveal,
            title: const Text('Show Card Reveal'),
            onChanged: _toggleCardReveal,
            activeColor: Colors.orange,
          ),
          SwitchListTile(
            value: _showWinnerCelebration,
            title: const Text('Show Winner Celebration'),
            onChanged: _toggleWinnerCelebration,
            activeColor: Colors.orange,
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Main Menu'),
            ),
          ),
        ],
      ),
    );
  }
}
