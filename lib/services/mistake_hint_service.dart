import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class MistakeHintService {
  MistakeHintService._();
  static final MistakeHintService instance = MistakeHintService._();
  static const _prefsKey = 'shown_mistake_hints';
  final Set<String> _shown = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _shown
      ..clear()
      ..addAll(prefs.getStringList(_prefsKey) ?? []);
  }

  bool isShown(String tag) => _shown.contains(tag);

  Future<void> markShown(String tag) async {
    if (_shown.contains(tag)) return;
    _shown.add(tag);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _shown.toList());
  }
}
