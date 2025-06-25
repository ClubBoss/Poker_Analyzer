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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _events
      ..clear()
      ..addAll(raw.map((e) => jsonDecode(e) as Map<String, dynamic>));
    notifyListeners();
  }

  Future<void> log(String action) async {
    final event = {
      'event': action,
      'time': DateTime.now().toIso8601String(),
    };
    _events.add(event);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _events.map((e) => jsonEncode(e)).toList(),
    );
    notifyListeners();
  }

  List<Map<String, dynamic>> export() => events;

  Map<String, dynamic> toMap() => {'events': _events};

  Future<void> applyMap(Map<String, dynamic> data) async {
    final list = data['events'];
    if (list is List) {
      final existing = {for (final e in _events) jsonEncode(e)};
      bool changed = false;
      for (final item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final enc = jsonEncode(map);
          if (!existing.contains(enc)) {
            _events.add(map);
            changed = true;
          }
        }
      }
      if (changed) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _prefsKey,
          _events.map((e) => jsonEncode(e)).toList(),
        );
        notifyListeners();
      }
    }
  }
}
