import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'package:flutter/widgets.dart';

import 'smart_booster_unlocker.dart';
import 'training_session_service.dart';
import 'session_log_service.dart';
import 'tag_mastery_service.dart';

/// Schedules [SmartBoosterUnlocker.schedule] on session end or app resume.
class SmartBoosterUnlockScheduler with WidgetsBindingObserver {
  SmartBoosterUnlockScheduler({
    required this.sessions,
    SmartBoosterUnlocker? unlocker,
    this.debounce = const Duration(minutes: 15),
  }) : unlocker = unlocker ??
            SmartBoosterUnlocker(
              mastery: TagMasteryService(
                logs: SessionLogService(sessions: sessions),
              ),
            );

  final TrainingSessionService sessions;
  final SmartBoosterUnlocker unlocker;
  final Duration debounce;

  static const String _prefsKey = 'smart_booster_unlock_last_run';

  VoidCallback? _listener;
  DateTime? _lastRun;
  bool _running = false;

  /// Begin observing lifecycle and session events.
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _listener = _onSessionChange;
    sessions.addListener(_listener!);
    _lastRun = await _loadLastRun();
    await _maybeRun();
  }

  /// Stop observing events.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    if (_listener != null) sessions.removeListener(_listener!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeRun();
    }
  }

  void _onSessionChange() {
    final s = sessions.session;
    if (s != null && s.completedAt != null) {
      _maybeRun();
    }
  }

  Future<void> _maybeRun() async {
    if (_running) return;
    final last = _lastRun;
    if (last != null && DateTime.now().difference(last) < debounce) return;
    _running = true;
    try {
      await unlocker.schedule();
      _lastRun = DateTime.now();
      await _saveLastRun(_lastRun!);
    } finally {
      _running = false;
    }
  }

  Future<DateTime?> _loadLastRun() async {
    final prefs = await PreferencesService.getInstance();
    final str = prefs.getString(_prefsKey);
    return str == null ? null : DateTime.tryParse(str);
  }

  Future<void> _saveLastRun(DateTime time) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, time.toIso8601String());
  }
}

