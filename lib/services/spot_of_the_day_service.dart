import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

import '../models/training_spot.dart';
import '../models/spot_of_day_history_entry.dart';

class SpotOfTheDayService extends ChangeNotifier {
  static const _dateKey = 'spot_of_day_date';
  static const _indexKey = 'spot_of_day_index';
  static const _resultKey = 'spot_of_day_result';
  static const _historyKey = 'spot_of_day_history';

  TrainingSpot? _spot;
  DateTime? _date;
  String? _result;
  List<SpotOfDayHistoryEntry> _history = [];
  Timer? _timer;

  bool? get correct {
    if (_spot == null || _result == null || _spot!.recommendedAction == null) {
      return null;
    }
    return _result == _spot!.recommendedAction;
  }

  TrainingSpot? get spot => _spot;
  TrainingSpot? get currentSpot => _spot;
  String? get result => _result;
  List<SpotOfDayHistoryEntry> get history => List.unmodifiable(_history);

  bool _isSameDay(DateTime a, DateTime b) {
    final ua = a.toUtc();
    final ub = b.toUtc();
    return ua.year == ub.year && ua.month == ub.month && ua.day == ub.day;
  }

  Future<void> _loadHistory() async {
    final prefs = await PreferencesService.getInstance();
    final stored = prefs.getStringList(_historyKey) ?? [];
    _history = [];
    for (final item in stored) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          _history.add(
              SpotOfDayHistoryEntry.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await PreferencesService.getInstance();
    final list = [for (final e in _history) jsonEncode(e.toJson())];
    await prefs.setStringList(_historyKey, list);
  }

  Future<List<TrainingSpot>> _loadAllSpots() async {
    final data = await rootBundle.loadString('assets/spots/spots.json');
    final list = jsonDecode(data) as List;
    return [
      for (final e in list)
        TrainingSpot.fromJson(Map<String, dynamic>.from(e as Map))
    ];
  }

  Future<List<TrainingSpot>> loadAllSpots() => _loadAllSpots();

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    await _loadHistory();
    final dateStr = prefs.getString(_dateKey);
    final index = prefs.getInt(_indexKey);
    _result = prefs.getString(_resultKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (index != null && _date != null && _isSameDay(_date!, DateTime.now())) {
      final spots = await _loadAllSpots();
      if (index >= 0 && index < spots.length) {
        _spot = spots[index];
      }
      final idx = _history.indexWhere((e) => _isSameDay(e.date, _date!));
      if (idx < 0) {
        _history.add(SpotOfDayHistoryEntry(
            date: _date!,
            spotIndex: index,
            recommendedAction: _spot?.recommendedAction));
        await _saveHistory();
      } else if (_history[idx].recommendedAction == null &&
          _spot?.recommendedAction != null) {
        final entry = _history[idx];
        _history[idx] = entry.copyWith(
          recommendedAction: _spot!.recommendedAction,
          correct: entry.userAction != null
              ? entry.userAction == _spot!.recommendedAction
              : null,
        );
        await _saveHistory();
      } else if (_history[idx].correct == null &&
          _history[idx].userAction != null &&
          _history[idx].recommendedAction != null) {
        final entry = _history[idx];
        _history[idx] = entry.copyWith(
            correct:
                entry.userAction == entry.recommendedAction);
        await _saveHistory();
      }
    }
    _scheduleTimer();
    notifyListeners();
  }

  Future<void> ensureTodaySpot() async {
    if (_spot != null && _date != null && _isSameDay(_date!, DateTime.now())) {
      return;
    }
    final spots = await _loadAllSpots();
    if (spots.isEmpty) return;
    final rnd = Random().nextInt(spots.length);
    _spot = spots[rnd];
    _date = DateTime.now();
    _result = null;
    _history.add(SpotOfDayHistoryEntry(
        date: _date!, spotIndex: rnd, recommendedAction: _spot?.recommendedAction));
    await _saveHistory();
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setInt(_indexKey, rnd);
    await prefs.remove(_resultKey);
    _scheduleTimer();
    notifyListeners();
  }

  Future<void> saveResult(String action) async {
    _result = action;
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_resultKey, action);
    if (_date != null) {
      final idx = _history.indexWhere((e) => _isSameDay(e.date, _date!));
      if (idx >= 0) {
        final entry = _history[idx];
        _history[idx] = entry.copyWith(
            userAction: action,
            recommendedAction: entry.recommendedAction ?? _spot?.recommendedAction,
            correct: _spot?.recommendedAction != null
                ? action == _spot!.recommendedAction
                : null);
        await _saveHistory();
      }
    }
    notifyListeners();
  }

  Future<void> updateHistoryEntry(DateTime date, String action,
      {String? recommendedAction}) async {
    final idx = _history.indexWhere((e) => _isSameDay(e.date, date));
    if (idx < 0) return;
    final entry = _history[idx];
    final rec = recommendedAction ?? entry.recommendedAction;
    _history[idx] = entry.copyWith(
      userAction: action,
      recommendedAction: rec,
      correct: rec != null ? action == rec : null,
    );
    await _saveHistory();
    notifyListeners();
  }

  void _scheduleTimer() {
    _timer?.cancel();
    final now = DateTime.now().toUtc();
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), ensureTodaySpot);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
