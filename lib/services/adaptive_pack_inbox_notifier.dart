import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_pack_recommender_service.dart';
import 'decay_booster_reminder_orchestrator.dart';
import 'inbox_booster_tracker_service.dart';

/// Background notifier that posts high urgency adaptive pack suggestions
/// to the theory inbox when no memory banners are visible.
class AdaptivePackInboxNotifier with WidgetsBindingObserver {
  final AdaptivePackRecommenderService recommender;
  final DecayBoosterReminderOrchestrator orchestrator;
  final InboxBoosterTrackerService inbox;
  final Duration cooldown;

  AdaptivePackInboxNotifier({
    required this.recommender,
    DecayBoosterReminderOrchestrator? orchestrator,
    InboxBoosterTrackerService? inbox,
    this.cooldown = const Duration(hours: 6),
  })  : orchestrator = orchestrator ?? DecayBoosterReminderOrchestrator(),
        inbox = inbox ?? InboxBoosterTrackerService.instance;

  static const String _lastKey = 'adaptive_pack_inbox_last';

  /// Begin observing lifecycle events.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _maybeNotify();
  }

  /// Stop observing lifecycle events.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeNotify();
    }
  }

  Future<DateTime?> _lastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    return str == null ? null : DateTime.tryParse(str);
  }

  Future<void> _setLastRun(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, time.toIso8601String());
  }

  Future<void> _maybeNotify() async {
    final last = await _lastRun();
    final now = DateTime.now();
    if (last != null && now.difference(last) < cooldown) return;

    final memory = await orchestrator.getRankedReminders();
    if (memory.isNotEmpty) return;

    final recs = await recommender.recommend(count: 1);
    if (recs.isEmpty) return;
    final AdaptivePackRecommendation top = recs.first;
    if (top.score < 4.0) return;

    final id = 'pack:${top.pack.id}';
    if (await inbox.wasRecentlyShown(id)) return;
    await inbox.addToInbox(id);
    await _setLastRun(now);
  }
}
