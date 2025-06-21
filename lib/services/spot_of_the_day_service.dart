import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_spot.dart';

class SpotOfTheDayService extends ChangeNotifier {
  static const _dateKey = 'spot_of_day_date';
  static const _indexKey = 'spot_of_day_index';
  static const _resultKey = 'spot_of_day_result';

  TrainingSpot? _spot;
  DateTime? _date;
  String? _result;

  TrainingSpot? get spot => _spot;
  String? get result => _result;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<List<TrainingSpot>> _loadAllSpots() async {
    final data = await rootBundle.loadString('assets/spots/spots.json');
    final list = jsonDecode(data) as List;
    return [
      for (final e in list)
        TrainingSpot.fromJson(Map<String, dynamic>.from(e as Map))
    ];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_dateKey);
    final index = prefs.getInt(_indexKey);
    _result = prefs.getString(_resultKey);
    _date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (index != null && _date != null && _isSameDay(_date!, DateTime.now())) {
      final spots = await _loadAllSpots();
      if (index >= 0 && index < spots.length) {
        _spot = spots[index];
      }
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _date!.toIso8601String());
    await prefs.setInt(_indexKey, rnd);
    await prefs.remove(_resultKey);
    notifyListeners();
  }

  Future<void> saveResult(String action) async {
    _result = action;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resultKey, action);
    notifyListeners();
  }
}
