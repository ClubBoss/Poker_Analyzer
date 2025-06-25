import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyTipService extends ChangeNotifier {
  static const _indexKey = 'daily_tip_index';
  static const _dateKey = 'daily_tip_date';

  static const _tips = [
    'Review your big hands after each session.',
    'Stay patient and wait for good spots.',
    'Focus on playing in position.',
    'Manage your bankroll wisely.',
    'Take breaks to avoid tilt.',
    'Study opponents\' tendencies.',
    "Don't bluff too often.",
    'Keep emotions in check.',
    'Analyze your mistakes regularly.',
    'Stay disciplined with starting hands.'
  ];

  String _tip = '';
  DateTime? _date;

  String get tip => _tip;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_indexKey);
    final dateStr = prefs.getString(_dateKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (index != null && _date != null && _sameDay(_date!, DateTime.now())) {
      if (index >= 0 && index < _tips.length) {
        _tip = _tips[index];
      }
    } else {
      await _select();
    }
    notifyListeners();
  }

  Future<void> _select() async {
    final rnd = Random().nextInt(_tips.length);
    _tip = _tips[rnd];
    _date = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_indexKey, rnd);
    await prefs.setString(_dateKey, _date!.toIso8601String());
  }

  Future<void> ensureTodayTip() async {
    if (_date == null || !_sameDay(_date!, DateTime.now())) {
      await _select();
      notifyListeners();
    }
  }
}
