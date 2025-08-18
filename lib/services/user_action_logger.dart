import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserActionLogger extends ChangeNotifier {
  static final UserActionLogger _instance = UserActionLogger._();
  factory UserActionLogger() => _instance;
  UserActionLogger._();
  static UserActionLogger get instance => _instance;

  static const _prefsKey = 'user_action_log';
  final List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
  DateTime? _last;
  String? _lastAction;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _events
      ..clear()
      ..addAll(raw.map((e) => jsonDecode(e) as Map<String, dynamic>));
    notifyListeners();
  }

  Future<void> log(String action) async {
    final event = {'event': action, 'time': DateTime.now().toIso8601String()};
    _events.add(event);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _events.map((e) => jsonEncode(e)).toList(),
    );
    notifyListeners();
  }

  Future<void> logThrottled(
    String action, [
    Duration delay = const Duration(seconds: 2),
  ]) async {
    final now = DateTime.now();
    if (_lastAction == action &&
        _last != null &&
        now.difference(_last!) < delay) {
      return;
    }
    _lastAction = action;
    _last = now;
    await log(action);
  }

  Future<void> logEvent(Map<String, dynamic> event) async {
    event['time'] ??= DateTime.now().toIso8601String();
    _events.add(event);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _events.map((e) => jsonEncode(e)).toList(),
    );
    notifyListeners();
  }

  List<Map<String, dynamic>> export() => events;
}
