import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/training_result.dart';
import 'training_history_controller.dart';

class TrainingHistoryViewModel extends ChangeNotifier {
  TrainingHistoryViewModel(this._controller);

  final TrainingHistoryController _controller;
  final List<TrainingResult> _history = [];
  int _filterDays = 7;

  List<TrainingResult> get history => List.unmodifiable(_history);
  int get filterDays => _filterDays;

  Future<void> load() async {
    final loaded = await _controller.loadHistory();
    _history
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> clear() async {
    await _controller.clearHistory();
    _history.clear();
    notifyListeners();
  }

  Future<void> setFilterDays(int days) async {
    _filterDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_history_filter_days', days);
    notifyListeners();
  }

  List<TrainingResult> getFilteredHistory() {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    return _history.where((r) => r.date.isAfter(cutoff)).toList();
  }

  double averageAccuracy() {
    final list = getFilteredHistory();
    if (list.isEmpty) return 0;
    final total = list.fold<double>(0, (sum, r) => sum + r.accuracy);
    return total / list.length;
  }
}
