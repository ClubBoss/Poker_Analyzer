import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingProgressTrackerService extends ChangeNotifier {
  TrainingProgressTrackerService._();
  static final instance = TrainingProgressTrackerService._();

  String _key(String packId) => 'pack_progress_$packId';

  Future<Set<String>> getCompletedSpotIds(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(packId));
    return list?.toSet() ?? {};
  }

  Future<void> recordSpotCompleted(String packId, String spotId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(packId);
    final ids = prefs.getStringList(key)?.toSet() ?? {};
    if (ids.add(spotId)) {
      await prefs.setStringList(key, ids.toList());
      notifyListeners();
    }
  }
}

