import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/widgets.dart';
import 'decay_booster_injector_scheduler.dart';

/// Tracks last active timestamp to estimate user idle duration.
class AppUsageTracker with WidgetsBindingObserver {
  AppUsageTracker._();
  static final AppUsageTracker instance = AppUsageTracker._();

  static const String _prefsKey = 'app_usage_last_active';

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await markActive();
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      markActive();
    }
  }

  /// Records current time as last active moment.
  Future<void> markActive() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, DateTime.now().toIso8601String());
    unawaited(DecayBoosterInjectorScheduler.instance.maybeInject());
  }

  /// Returns duration since the app was last active.
  Future<Duration> idleDuration() async {
    final prefs = await PreferencesService.getInstance();
    final str = prefs.getString(_prefsKey);
    final last = str != null ? DateTime.tryParse(str) : null;
    if (last == null) return Duration.zero;
    return DateTime.now().difference(last);
  }
}
