import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionNoteService extends ChangeNotifier {
  static const _prefsKey = 'session_notes';

  final Map<int, String> _notes = {};

  String noteFor(int sessionId) => _notes[sessionId] ?? '';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        _notes
          ..clear()
          ..addEntries(data.entries.map((e) => MapEntry(int.parse(e.key), e.value as String)));
      } catch (_) {
        _notes.clear();
      }
    }
    notifyListeners();
  }

  Future<void> setNote(int sessionId, String note) async {
    _notes[sessionId] = note;
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in _notes.entries) e.key.toString(): e.value};
    await prefs.setString(_prefsKey, jsonEncode(data));
    notifyListeners();
  }
}
