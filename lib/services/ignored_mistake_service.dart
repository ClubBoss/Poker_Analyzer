import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class IgnoredMistakeService extends ChangeNotifier {
  static const _prefsKey = 'ignored_mistakes';

  final Set<String> _ignored = {};

  Set<String> get ignored => _ignored;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final list = prefs.getStringList(_prefsKey);
    _ignored
      ..clear()
      ..addAll(list ?? []);
    notifyListeners();
  }

  Future<void> ignore(String key) async {
    if (_ignored.contains(key)) return;
    _ignored.add(key);
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_prefsKey, _ignored.toList());
    notifyListeners();
  }

  Future<void> reset() async {
    if (_ignored.isEmpty) return;
    _ignored.clear();
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
