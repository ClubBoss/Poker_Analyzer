import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IgnoredMistakeService extends ChangeNotifier {
  static const _prefsKey = 'ignored_mistakes';

  final Set<String> _ignored = {};

  Set<String> get ignored => _ignored;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey);
    _ignored
      ..clear()
      ..addAll(list ?? []);
    notifyListeners();
  }

  Future<void> ignore(String key) async {
    if (_ignored.contains(key)) return;
    _ignored.add(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ignored.toList());
    notifyListeners();
  }

  Future<void> reset() async {
    if (_ignored.isEmpty) return;
    _ignored.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
