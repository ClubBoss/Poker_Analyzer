import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template.dart';
import 'training_gap_notification_service.dart';
import 'training_history_service_v2.dart';
import 'app_settings_service.dart';
import 'daily_reminder_scheduler.dart';

class SuggestedPackPushService {
  static final SuggestedPackPushService instance = SuggestedPackPushService._();
  SuggestedPackPushService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _lastPushKey = 'suggested_pack_push_last';

  Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> schedulePushReminder() async {
    await _init();
    await AppSettingsService.instance.load();
    if (!AppSettingsService.instance.notificationsEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastPushKey);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last).inHours < 24) {
        return;
      }
    }

    final history = await TrainingHistoryServiceV2.getHistory(limit: 1);
    DateTime? lastTraining;
    if (history.isNotEmpty) lastTraining = history.first.timestamp;
    if (lastTraining != null &&
        DateTime.now().difference(lastTraining).inDays <= 3) {
      return;
    }

    final TrainingPackTemplate? tpl =
        await const TrainingGapNotificationService().suggestNextPack();
    if (tpl == null) return;

    final body = '📈 Улучшите свои слабые места - начните пак "[${tpl.name}]"';
    await _plugin.show(
      104,
      'Poker Analyzer',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('suggested_pack', 'Suggested Pack'),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await DailyReminderScheduler.instance.scheduleDailyReminder(
      packName: tpl.name,
    );
    await prefs.setString(_lastPushKey, DateTime.now().toIso8601String());
  }
}
