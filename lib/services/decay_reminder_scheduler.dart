import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'app_settings_service.dart';
import 'tag_insight_reminder_engine.dart';
import 'skill_loss_feed_engine.dart';
import 'tag_mastery_history_service.dart';
import 'pack_library_service.dart';
import 'training_session_launcher.dart';

/// Background scheduler that surfaces high urgency skill decay.
class DecayReminderScheduler {
  DecayReminderScheduler._();
  static final DecayReminderScheduler instance = DecayReminderScheduler._();

  static const String _task = 'decayReminderTask';
  static const String _tagKey = 'decay_reminder_last_tag';
  static const String _timeKey = 'decay_reminder_last_time';
  static const int _notificationId = 223;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) async {
        final id = r.payload;
        if (id == null) return;
        final pack = await PackLibraryService.instance.getById(id);
        if (pack != null) {
          await const TrainingSessionLauncher().launch(pack);
        }
      },
    );
    tz.initializeTimeZones();
    _initialized = true;
  }

  /// Registers the periodic background task.
  Future<void> register() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      _task,
      _task,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 1),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  static void _callbackDispatcher() {
    Workmanager().executeTask((task, _) async {
      if (task == _task) {
        await instance._run();
      }
      return true;
    });
  }

  Future<void> _run() async {
    await _init();
    await AppSettingsService.instance.load();
    if (!AppSettingsService.instance.notificationsEnabled) return;

    final reminder = TagInsightReminderEngine(history: TagMasteryHistoryService());
    final losses = await reminder.loadLosses();
    final feed =
        await const SkillLossFeedEngine().buildFeed(losses, maxItems: losses.length);
    if (feed.isEmpty) return;
    final item = feed.firstWhere(
      (e) => e.urgencyScore >= 1.0,
      orElse: () => feed.first,
    );
    if (item.urgencyScore < 1.0) return;

    final prefs = await SharedPreferences.getInstance();
    final lastTag = prefs.getString(_tagKey);
    final lastTimeStr = prefs.getString(_timeKey);
    final lastTime = lastTimeStr != null ? DateTime.tryParse(lastTimeStr) : null;
    if (lastTag == item.tag && lastTime != null && DateTime.now().difference(lastTime).inDays < 1) {
      return;
    }

    await _plugin.show(
      _notificationId,
      '⏳ Skill slipping away: ${item.tag}',
      'Tap to train before it\'s lost',
      const NotificationDetails(
        android: AndroidNotificationDetails('decay_reminder', 'Decay Reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      payload: item.suggestedPackId,
    );
    await prefs.setString(_tagKey, item.tag);
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
  }
}
