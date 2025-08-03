import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'cloud_retry_policy.dart';
import 'cloud_sync_service.dart';
import 'xp_tracker_service.dart';
import 'streak_progress_service.dart';

/// Tracks the number of consecutive days the app was opened.
///
/// The streak information is persisted using [SharedPreferences] so it
/// survives app restarts. Every time the service is loaded or explicitly
/// refreshed it compares today's date with the last stored activity date and
/// updates the counter accordingly.
class StreakService extends ChangeNotifier {
  StreakService({this.cloud, required this.xp});

  final CloudSyncService? cloud;
  final XPTrackerService xp;
  static const _lastOpenKey = 'streak_last_open';
  static const _countKey = 'streak_count';
  static const _errorKey = 'error_free_streak';
  static const _historyKey = 'streak_history';
  static const bonusThreshold = 3;
  static const bonusMultiplier = 1.5;

  static const _trainingCountKey = 'training_streak_count';
  static const _trainingDateKey = 'training_streak_date';

  DateTime? _lastOpen;
  int _count = 0;
  bool _increased = false;
  int _errorFreeStreak = 0;
  Map<String, int> _history = {};
  final ValueNotifier<int> streak = ValueNotifier(0);
  DateTime? _lastTrainingDate;

  int get count => _count;
  bool get hasBonus => _count >= bonusThreshold;
  bool get increased => _increased;
  int get errorFreeStreak => _errorFreeStreak;
  List<MapEntry<DateTime, int>> get history {
    final list =
        _history.entries
            .map((e) => MapEntry(DateTime.parse(e.key), e.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  /// Returns true if the streak increased since the last check.
  bool consumeIncreaseFlag() {
    final value = _increased;
    _increased = false;
    return value;
  }

  /// Loads the persisted streak information and refreshes it for today.
  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastOpenKey);
    _lastOpen = lastStr != null ? DateTime.tryParse(lastStr) : null;
    _count = prefs.getInt(_countKey) ?? 0;
    _errorFreeStreak = prefs.getInt(_errorKey) ?? 0;
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _history = {for (final e in data.entries) e.key: e.value as int};
    }
    streak.value = prefs.getInt(_trainingCountKey) ?? 0;
    final tStr = prefs.getString(_trainingDateKey);
    _lastTrainingDate = tStr != null ? DateTime.tryParse(tStr) : null;
    _verifyTrainingStreak();
    if (cloud != null && cloud!.uid != null) {
      try {
        final doc = await CloudRetryPolicy.execute(
          () => FirebaseFirestore.instance
              .collection('stats')
              .doc(cloud!.uid)
              .collection('streak')
              .doc('main')
              .get(),
        );
        if (doc.exists) {
          final data = doc.data()!;
          streak.value = (data['current'] as num?)?.toInt() ?? streak.value;
          final d = DateTime.tryParse(data['last'] as String? ?? '');
          if (d != null) _lastTrainingDate = d;
          await _saveTraining();
        }
      } catch (_) {}
    }
    await updateStreak();
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    if (_lastOpen != null) {
      await prefs.setString(_lastOpenKey, _lastOpen!.toIso8601String());
    } else {
      await prefs.remove(_lastOpenKey);
    }
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_errorKey, _errorFreeStreak);
    await prefs.setString(_historyKey, jsonEncode(_history));
  }

  Future<void> _saveTraining() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_trainingCountKey, streak.value);
    if (_lastTrainingDate != null) {
      await prefs.setString(
        _trainingDateKey,
        _lastTrainingDate!.toIso8601String(),
      );
    } else {
      await prefs.remove(_trainingDateKey);
    }
    if (cloud != null && cloud!.uid != null) {
      final data = {
        'current': streak.value,
        'last': _lastTrainingDate?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await CloudRetryPolicy.execute(
        () => FirebaseFirestore.instance
            .collection('stats')
            .doc(cloud!.uid)
            .collection('streak')
            .doc('main')
            .set(data),
      );
    }
  }

  void _verifyTrainingStreak() {
    if (_lastTrainingDate != null) {
      final today = DateTime.now();
      final last = DateTime(
        _lastTrainingDate!.year,
        _lastTrainingDate!.month,
        _lastTrainingDate!.day,
      );
      if (today.difference(last).inDays > 1 && streak.value != 0) {
        streak.value = 0;
        unawaited(xp.add(xp: 0, source: 'streak_update', streak: 0));
      }
    }
  }

  /// Compares the saved date with today and updates the streak accordingly.
  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _verifyTrainingStreak();
    bool increased = false;
    final prev = _count;

    if (_lastOpen == null) {
      // First app launch.
      _count = 1;
      _lastOpen = today;
      increased = true;
    } else {
      final last = DateTime(_lastOpen!.year, _lastOpen!.month, _lastOpen!.day);
      final diff = today.difference(last).inDays;

      if (diff == 1) {
        _count += 1;
        _lastOpen = today;
        increased = true;
      } else if (diff != 0) {
        // More than a day has passed or clock was changed.
        _count = 1;
        _lastOpen = today;
        increased = true;
      }
    }

    final key = today.toIso8601String().split('T').first;
    _history[key] = _count;
    final keys = _history.keys.toList()..sort();
    while (keys.length > 30) {
      _history.remove(keys.first);
      keys.removeAt(0);
    }
    _increased = increased;
    if (_count != prev) {
      unawaited(xp.add(xp: 0, source: 'streak_update', streak: _count));
    }
    await _save();
    notifyListeners();
  }

  Future<void> updateErrorFreeStreak(bool correct) async {
    final next = correct ? _errorFreeStreak + 1 : 0;
    if (next == _errorFreeStreak) return;
    _errorFreeStreak = next;
    await _save();
    notifyListeners();
  }

  Future<void> onFinish() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastTrainingDate != null) {
      final last = DateTime(
        _lastTrainingDate!.year,
        _lastTrainingDate!.month,
        _lastTrainingDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        streak.value += 1;
      } else if (diff > 1) {
        streak.value = 1;
      }
    } else {
      streak.value = 1;
    }
    unawaited(xp.add(xp: 0, source: 'streak_update', streak: streak.value));
    _lastTrainingDate = today;
    await _saveTraining();
    await StreakProgressService.instance.registerDailyActivity();
    notifyListeners();
  }
}
