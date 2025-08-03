import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

class MistakeHintService {
  MistakeHintService._();
  static final MistakeHintService instance = MistakeHintService._();
  static const _prefsKey = 'shown_mistake_hints';
  final Set<String> _shown = {};

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _shown
      ..clear()
      ..addAll(prefs.getStringList(_prefsKey) ?? []);
  }

  bool isShown(String tag) => _shown.contains(tag);

  Future<void> markShown(String tag) async {
    if (_shown.contains(tag)) return;
    _shown.add(tag);
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_prefsKey, _shown.toList());
  }

  static const _hints = [
    'Swipe down to exit training',
    'Toggle EV/ICM mode for alternative view',
    'Focus on decision logic, not results',
  ];

  String getHint() {
    _hintIndex = (_hintIndex + 1) % _hints.length;
    return _hints[_hintIndex];
  }

  int _hintIndex = 0;
}
