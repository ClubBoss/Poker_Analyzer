import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'decay_spot_booster_engine.dart';

/// Background job that periodically enqueues decay boosters.
class DecayBoosterCronJob with WidgetsBindingObserver {
  DecayBoosterCronJob({DecaySpotBoosterEngine? engine})
      : engine = engine ?? DecaySpotBoosterEngine();

  final DecaySpotBoosterEngine engine;

  static final DecayBoosterCronJob instance = DecayBoosterCronJob();

  static const String _prefsKey = 'decay_booster_cron_last';

  bool _running = false;

  Future<void> start() async {
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
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsKey);
      final last = str != null ? DateTime.tryParse(str) : null;
      if (last == null || DateTime.now().difference(last).inDays >= 7) {
        await engine.enqueueDecayBoosters();
        await prefs.setString(_prefsKey, DateTime.now().toIso8601String());
      }
    } finally {
      _running = false;
    }
  }
}
