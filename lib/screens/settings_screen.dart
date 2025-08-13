import 'package:flutter/material.dart';

import '../services/user_preferences_service.dart';
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
import '../services/daily_challenge_notification_service.dart';
import '../services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'lesson_track_library_screen.dart';
import '../services/skill_tree_settings_service.dart';

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
  late bool _hideCompletedPrereqs;
  late Color _accentColor;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _challengeTime = const TimeOfDay(hour: 12, minute: 0);
  late VoidCallback _hideCompletedListener;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _showPotAnimation = prefs.showPotAnimation;
    _showCardReveal = prefs.showCardReveal;
    _showWinnerCelebration = prefs.showWinnerCelebration;
    _showActionHints = prefs.showActionHints;
    _coachMode = prefs.coachMode;
    _simpleNavigation = prefs.simpleNavigation;
    final stService = SkillTreeSettingsService.instance;
    _hideCompletedPrereqs = stService.hideCompletedPrereqs.value;
    _hideCompletedListener = () => setState(
        () => _hideCompletedPrereqs = stService.hideCompletedPrereqs.value);
    stService.hideCompletedPrereqs.addListener(_hideCompletedListener);
    stService.load();
    _accentColor = prefs.accentColor;
    NotificationService.getReminderTime(context)
        .then((t) => setState(() => _reminderTime = t));
    DailyChallengeNotificationService.getScheduledTime()
        .then((t) => setState(() => _challengeTime = t));
  }

  Future<void> _togglePotAnimation(bool value) async {
    setState(() => _showPotAnimation = value);
    await context.read<UserPreferencesService>().setShowPotAnimation(value);
  }

  Future<void> _toggleCardReveal(bool value) async {
    setState(() => _showCardReveal = value);
    await context.read<UserPreferencesService>().setShowCardReveal(value);
  }

  Future<void> _toggleWinnerCelebration(bool value) async {
    setState(() => _showWinnerCelebration = value);
    await context
        .read<UserPreferencesService>()
        .setShowWinnerCelebration(value);
  }

  Future<void> _toggleActionHints(bool value) async {
    setState(() => _showActionHints = value);
    await context.read<UserPreferencesService>().setShowActionHints(value);
  }

  Future<void> _toggleCoachMode(bool value) async {
    setState(() => _coachMode = value);
    await context.read<UserPreferencesService>().setCoachMode(value);
  }

  Future<void> _toggleSimpleNavigation(bool value) async {
    setState(() => _simpleNavigation = value);
    await context.read<UserPreferencesService>().setSimpleNavigation(value);
  }

  Future<void> _toggleHideCompletedPrereqs(bool value) async {
    await SkillTreeSettingsService.instance.setHideCompletedPrereqs(value);
  }

  @override
  void dispose() {
    SkillTreeSettingsService.instance.hideCompletedPrereqs
        .removeListener(_hideCompletedListener);
    super.dispose();
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

  Future<void> _pickChallengeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _challengeTime,
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_challenge_reminder_hour', picked.hour);
      await prefs.setInt('daily_challenge_reminder_minute', picked.minute);
      await DailyChallengeNotificationService.scheduleDailyReminder(
          time: picked);
      setState(() => _challengeTime = picked);
    }
  }

  Future<void> _pickAccentColor() async {
    Color selected = _accentColor;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accent Color'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => BlockPicker(
            pickerColor: selected,
            onColorChanged: (c) => setStateDialog(() => selected = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      await context.read<UserPreferencesService>().setAccentColor(result);
      setState(() => _accentColor = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
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
                MaterialPageRoute(builder: (_) => const TagManagementScreen()),
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
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
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
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
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
            SwitchListTile(
              value: _hideCompletedPrereqs,
              title: const Text('Hide completed prerequisites'),
              subtitle:
                  const Text("Only show requirements you haven't finished yet"),
              onChanged: _toggleHideCompletedPrereqs,
              activeColor: Colors.orange,
            ),
            ListTile(
              title: const Text('⏰ Напоминание о челлендже'),
              subtitle: Text(_challengeTime.format(context)),
              trailing: TextButton(
                onPressed: _pickChallengeTime,
                child: const Text('Изменить'),
              ),
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(_reminderTime.format(context)),
              onTap: _pickReminderTime,
            ),
            ListTile(
              title: const Text('Accent Color'),
              leading: CircleAvatar(backgroundColor: _accentColor),
              onTap: _pickAccentColor,
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Advanced Settings',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LessonTrackLibraryScreen()),
                );
              },
              child: const Text('Learning Tracks'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<RemoteConfigService>().reload(),
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
