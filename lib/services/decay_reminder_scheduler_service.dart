import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'booster_inbox_delivery_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'notification_service.dart';

/// Schedules a daily reminder if no decay booster was completed today.
class DecayReminderSchedulerService with WidgetsBindingObserver {
  final BoosterInboxDeliveryService inbox;
  final DecayTagRetentionTrackerService retention;

  DecayReminderSchedulerService({
    BoosterInboxDeliveryService? inbox,
    DecayTagRetentionTrackerService? retention,
  })  : inbox = inbox ?? BoosterInboxDeliveryService.instance,
        retention = retention ?? const DecayTagRetentionTrackerService();

  static const _prefsKey = 'decay_reminder_last';
  static const _id = 425;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await scheduleReminderIfNeeded();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleReminderIfNeeded();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Schedules the reminder notification for 19:00 if conditions allow.
  Future<void> scheduleReminderIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_prefsKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && _sameDay(last, now)) return;

    final tag = await inbox.getNextDeliverableTag();
    if (tag == null) return;
    final completed = await retention.getLastBoosterCompletion(tag);
    if (completed != null && _sameDay(completed, now)) return;

    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }

    await NotificationService.schedule(
      id: _id,
      when: when,
      body: '🔥 Не забудь повторить: streak под угрозой',
    );

    await prefs.setString(_prefsKey, now.toIso8601String());
  }
}
