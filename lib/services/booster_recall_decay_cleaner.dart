import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booster_recall_scheduler.dart';

/// Periodically trims outdated skipped booster records.
class BoosterRecallDecayCleaner with WidgetsBindingObserver {
  BoosterRecallDecayCleaner._();
  static final BoosterRecallDecayCleaner instance =
      BoosterRecallDecayCleaner._();

  static const String _lastKey = 'booster_recall_decay_last';

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _runIfNeeded();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runIfNeeded();
    }
  }

  Future<void> _runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    final last = str != null ? DateTime.tryParse(str) : null;
    if (last == null || DateTime.now().difference(last).inDays >= 7) {
      await BoosterRecallScheduler.instance.applyDecay();
      await prefs.setString(_lastKey, DateTime.now().toIso8601String());
    }
  }
}
