import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingStatsService extends ChangeNotifier {
  static TrainingStatsService? _instance;
  static TrainingStatsService? get instance => _instance;

  TrainingStatsService() {
    _instance = this;
  }
  static const _sessionsKey = 'stats_sessions';
  static const _handsKey = 'stats_hands';
  static const _mistakesKey = 'stats_mistakes';

  int _sessions = 0;
  int _hands = 0;
  int _mistakes = 0;

  final _sessionController = StreamController<int>.broadcast();
  final _handsController = StreamController<int>.broadcast();
  final _mistakeController = StreamController<int>.broadcast();

  int get sessionsCompleted => _sessions;
  int get handsReviewed => _hands;
  int get mistakesFixed => _mistakes;

  Stream<int> get sessionsStream => _sessionController.stream;
  Stream<int> get handsStream => _handsController.stream;
  Stream<int> get mistakesStream => _mistakeController.stream;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sessions = prefs.getInt(_sessionsKey) ?? 0;
    _hands = prefs.getInt(_handsKey) ?? 0;
    _mistakes = prefs.getInt(_mistakesKey) ?? 0;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionsKey, _sessions);
    await prefs.setInt(_handsKey, _hands);
    await prefs.setInt(_mistakesKey, _mistakes);
  }

  Future<void> incrementSessions() async {
    _sessions += 1;
    await _save();
    notifyListeners();
    _sessionController.add(_sessions);
  }

  Future<void> incrementHands([int count = 1]) async {
    _hands += count;
    await _save();
    notifyListeners();
    _handsController.add(_hands);
  }

  Future<void> incrementMistakes([int count = 1]) async {
    _mistakes += count;
    await _save();
    notifyListeners();
    _mistakeController.add(_mistakes);
  }

  @override
  void dispose() {
    _sessionController.close();
    _handsController.close();
    _mistakeController.close();
    super.dispose();
  }
}
