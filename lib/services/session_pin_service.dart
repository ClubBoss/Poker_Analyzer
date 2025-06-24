import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPinService extends ChangeNotifier {
  static const _prefsKey = 'pinned_sessions';

  final Set<int> _pinned = {};

  Set<int> get pinned => _pinned;

  bool isPinned(int id) => _pinned.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _pinned
      ..clear()
      ..addAll(stored.map(int.parse));
    notifyListeners();
  }

  Future<void> setPinned(int id, bool value) async {
    if (value) {
      _pinned.add(id);
    } else {
      _pinned.remove(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _pinned.map((e) => e.toString()).toList());
    notifyListeners();
  }
}
