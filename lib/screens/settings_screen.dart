import 'package:flutter/material.dart';

import '../user_preferences.dart';
import 'tag_management_screen.dart';
import 'cloud_sync_screen.dart';
import '../services/achievement_engine.dart';
import 'achievements_screen.dart';
import 'package:provider/provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showPotAnimation;
  late bool _showCardReveal;
  late bool _showWinnerCelebration;
  late bool _showActionHints;
  late bool _coachMode;

  @override
  void initState() {
    super.initState();
    final prefs = UserPreferences.instance;
    _showPotAnimation = prefs.showPotAnimation;
    _showCardReveal = prefs.showCardReveal;
    _showWinnerCelebration = prefs.showWinnerCelebration;
    _showActionHints = prefs.showActionHints;
    _coachMode = prefs.coachMode;
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

  Future<void> _toggleActionHints(bool value) async {
    setState(() => _showActionHints = value);
    await UserPreferences.instance.setShowActionHints(value);
  }

  Future<void> _toggleCoachMode(bool value) async {
    setState(() => _coachMode = value);
    await UserPreferences.instance.setCoachMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: 'Cloud Sync',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudSyncScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Manage Tags',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TagManagementScreen()),
              );
            },
          ),
          Consumer<AchievementEngine>(
            builder: (context, engine, child) {
              final count = engine.unseenCount;
              Widget icon = const Icon(Icons.emoji_events);
              if (count > 0) {
                icon = Stack(
                  children: [
                    const Icon(Icons.emoji_events),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: icon,
                tooltip: 'Achievements',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
            SwitchListTile(
              value: _showActionHints,
              title: const Text('Показывать подсказки к действиям'),
              onChanged: _toggleActionHints,
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              value: _coachMode,
              title: const Text('Режим тренера (Coach Mode)'),
              onChanged: _toggleCoachMode,
              activeColor: Colors.orange,
            ),
            Consumer<AuthService>(
              builder: (context, auth, child) {
                final email = auth.email;
                final text = email != null
                    ? 'Sign Out ($email)'
                    : 'Sign In with Google';
                return ElevatedButton(
                  onPressed: () async {
                    if (auth.currentUser == null) {
                      final ok = await auth.signInWithGoogle();
                      if (ok) {
                        await context.read<CloudSyncService>().syncDown();
                      }
                    } else {
                      await auth.signOut();
                    }
                  },
                  child: Text(text),
                );
              },
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<DateTime?>(
              valueListenable: context.read<CloudSyncService>().lastSync,
              builder: (context, value, child) {
                final text = value == null
                    ? 'Sync Now'
                    : 'Sync Now (last: ${value.toLocal().toString().split('.').first})';
                return ElevatedButton(
                  onPressed: () async {
                    final cloud = context.read<CloudSyncService>();
                    await cloud.syncUp();
                    await cloud.syncDown();
                  },
                  child: Text(text),
                );
              },
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
      ),
    );
  }
}
