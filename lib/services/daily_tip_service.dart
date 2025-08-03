import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class DailyTipService extends ChangeNotifier {
  static const _dataKey = 'daily_tip_data';
  static const _categoryKey = 'daily_tip_category';

  static const Map<String, List<String>> _tips = {
    'Strategy': [
      'Review your big hands after each session.',
      'Focus on playing in position.',
      'Study opponents\' tendencies.',
      "Don't bluff too often.",
      'Analyze your mistakes regularly.'
    ],
    'Discipline': [
      'Stay patient and wait for good spots.',
      'Manage your bankroll wisely.',
      'Take breaks to avoid tilt.',
      'Keep emotions in check.',
      'Stay disciplined with starting hands.'
    ],
    'Motivation': [
      'Believe in your edge and stay confident.',
      'Small improvements lead to big wins.',
      'Stick to your plan and keep grinding.',
      'Every session is a chance to learn.',
      'Focus on progress, not perfection.'
    ]
  };

  final Map<String, int> _indexes = {};
  final Map<String, DateTime> _dates = {};
  String _category = 'Strategy';
  String _tip = '';

  List<String> get categories => List.unmodifiable(_tips.keys);
  String get tip => _tip;
  String get category => _category;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _category = prefs.getString(_categoryKey) ?? _category;
    final raw = prefs.getString(_dataKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          final m = e.value;
          if (m is Map) {
            final i = m['i'];
            final d = m['d'];
            if (i is int) _indexes[e.key] = i;
            if (d is String) {
              final dt = DateTime.tryParse(d);
              if (dt != null) _dates[e.key] = dt;
            }
          }
        }
      } catch (_) {}
    }
    await ensureTodayTip();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    final data = {
      for (final c in _indexes.keys)
        c: {
          'i': _indexes[c],
          'd': _dates[c]?.toIso8601String(),
        }
    };
    await prefs.setString(_dataKey, jsonEncode(data));
    await prefs.setString(_categoryKey, _category);
  }

  Future<void> _select(String cat) async {
    final list = _tips[cat]!;
    final rnd = Random().nextInt(list.length);
    _indexes[cat] = rnd;
    _dates[cat] = DateTime.now();
    _tip = list[rnd];
    await _save();
  }

  Future<void> ensureTodayTip() async {
    final cat = _category;
    final idx = _indexes[cat];
    final date = _dates[cat];
    final list = _tips[cat]!;
    if (idx != null && date != null && _sameDay(date, DateTime.now())) {
      if (idx >= 0 && idx < list.length) {
        _tip = list[idx];
        return;
      }
    }
    await _select(cat);
    notifyListeners();
  }

  Future<void> setCategory(String cat) async {
    if (!_tips.containsKey(cat) || _category == cat) return;
    _category = cat;
    await ensureTodayTip();
    await _save();
    notifyListeners();
  }
}
