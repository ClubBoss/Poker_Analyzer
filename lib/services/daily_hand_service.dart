import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_hand.dart';
import '../models/training_pack.dart';

class DailyHandHistory {
  final DateTime date;
  final bool correct;

  DailyHandHistory({required this.date, required this.correct});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'correct': correct,
      };

  factory DailyHandHistory.fromJson(Map<String, dynamic> json) =>
      DailyHandHistory(
        date: DateTime.parse(json['date'] as String),
        correct: json['correct'] as bool? ?? false,
      );
}

class DailyHandService extends ChangeNotifier {
  static const _handKey = 'daily_hand_json';
  static const _dateKey = 'daily_hand_date';
  static const _resultKey = 'daily_hand_result';
  static const _historyKey = 'daily_hand_history';

  SavedHand? _hand;
  DateTime? _date;
  bool? _result;
  final List<DailyHandHistory> _history = [];

  SavedHand? get hand => _hand;
  DateTime? get date => _date;
  bool? get result => _result;
  List<DailyHandHistory> get history => List.unmodifiable(_history);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final handStr = prefs.getString(_handKey);
    final dateStr = prefs.getString(_dateKey);
    final resultVal = prefs.getBool(_resultKey);
    final histRaw = prefs.getStringList(_historyKey) ?? [];

    _hand = handStr != null
        ? SavedHand.fromJson(jsonDecode(handStr) as Map<String, dynamic>)
        : null;
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    _result = resultVal;
    _history
      ..clear()
      ..addAll(
        histRaw.map(
          (e) =>
              DailyHandHistory.fromJson(jsonDecode(e) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hand != null) {
      await prefs.setString(_handKey, jsonEncode(_hand!.toJson()));
    } else {
      await prefs.remove(_handKey);
    }
    if (_date != null) {
      await prefs.setString(_dateKey, _date!.toIso8601String());
    } else {
      await prefs.remove(_dateKey);
    }
    if (_result != null) {
      await prefs.setBool(_resultKey, _result!);
    } else {
      await prefs.remove(_resultKey);
    }
    await prefs.setStringList(_historyKey, [
      for (final h in _history) jsonEncode(h.toJson()),
    ]);
  }

  Future<void> setResult(bool correct) async {
    _result = correct;
    _history.add(DailyHandHistory(date: DateTime.now(), correct: correct));
    if (_history.length > 30) {
      _history.removeRange(0, _history.length - 30);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setHand(SavedHand hand) async {
    _hand = hand;
    _date = DateTime.now();
    _result = null;
    await _persist();
    notifyListeners();
  }

  Future<void> ensureTodayHand({List<TrainingPack>? packs}) async {
    if (_hand == null || _date == null || !_isSameDay(_date!, DateTime.now())) {
      SavedHand? newHand;
      if (packs != null && packs.isNotEmpty) {
        final allHands = <SavedHand>[];
        for (final p in packs) {
          allHands.addAll(p.hands);
        }
        if (allHands.isNotEmpty) {
          final rnd = Random().nextInt(allHands.length);
          newHand = allHands[rnd];
        }
      }
      if (newHand != null) {
        await setHand(newHand);
      } else {
        _hand = null;
        _date = DateTime.now();
        _result = null;
        await _persist();
      }
    }
  }
}
