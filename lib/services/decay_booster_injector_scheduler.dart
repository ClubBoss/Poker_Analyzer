import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'decay_booster_spot_injector.dart';

/// Schedules automatic injection of decay booster spots.
class DecayBoosterInjectorScheduler {
  DecayBoosterInjectorScheduler({DecayBoosterSpotInjector? injector})
      : injector = injector ?? DecayBoosterSpotInjector.instance;

  final DecayBoosterSpotInjector injector;

  static final DecayBoosterInjectorScheduler instance =
      DecayBoosterInjectorScheduler();

  static const String _prefsKey = 'decay_booster_inject_last';

  bool _running = false;

  /// Injects decayed spots if at least 24h passed since last injection.
  Future<void> maybeInject({DateTime? now}) async {
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsKey);
      final last = str != null ? DateTime.tryParse(str) : null;
      final current = now ?? DateTime.now();
      if (last == null || current.difference(last).inHours >= 24) {
        await injector.inject(now: now);
        await prefs.setString(_prefsKey, current.toIso8601String());
      }
    } finally {
      _running = false;
    }
  }
}
