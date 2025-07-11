import 'package:flutter/material.dart';

import '../user_preferences.dart';
import 'tag_management_screen.dart';
import 'cloud_sync_screen.dart';
import '../services/achievement_engine.dart';
import 'achievements_screen.dart';
import 'package:provider/provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../widgets/sync_status_widget.dart';
import 'evaluation_settings_screen.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';

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
  late bool _simpleNavigation;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    final prefs = UserPreferences.instance;
    _showPotAnimation = prefs.showPotAnimation;
    _showCardReveal = prefs.showCardReveal;
    _showWinnerCelebration = prefs.showWinnerCelebration;
    _showActionHints = prefs.showActionHints;
    _coachMode = prefs.coachMode;
    _simpleNavigation = prefs.simpleNavigation;
    NotificationService.getReminderTime(context)
        .then((t) => setState(() => _reminderTime = t));
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

  Future<void> _toggleSimpleNavigation(bool value) async {
    setState(() => _simpleNavigation = value);
    await UserPreferences.instance.setSimpleNavigation(value);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      await NotificationService.updateReminderTime(context, picked);
      setState(() => _reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context), 
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
            SwitchListTile(
              value: _simpleNavigation,
              title: const Text('Простой режим'),
              onChanged: _toggleSimpleNavigation,
              activeColor: Colors.orange,
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(_reminderTime.format(context)),
              onTap: _pickReminderTime,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EvaluationSettingsScreen(),
                  ),
                );
              },
              child: const Text('Evaluation Settings'),
            ),
            Consumer<AuthService>(
              builder: (context, auth, child) {
                if (auth.currentUser != null) {
                  final email = auth.email;
                  return ElevatedButton(
                    onPressed: auth.signOut,
                    child: Text('Sign Out ($email)'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await auth.signInWithGoogle();
                        if (ok) {
                          await context.read<CloudSyncService>().syncDown();
                          await context
                              .read<TrainingPackCloudSyncService>()
                              .syncDownStats();
                        }
                      },
                      child: const Text('Sign In with Google'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await auth.signInWithApple();
                        if (ok) {
                          await context.read<CloudSyncService>().syncDown();
                          await context
                              .read<TrainingPackCloudSyncService>()
                              .syncDownStats();
                        }
                      },
                      child: const Text('Sign In with Apple'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<RemoteConfigService>().reload(),
              child: const Text('Reload Remote Config'),
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
