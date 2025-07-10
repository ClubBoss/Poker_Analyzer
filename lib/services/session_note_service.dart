import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

class SessionNoteService extends ChangeNotifier {
  static const _prefsKey = 'session_notes';
  static const _timeKey = 'session_notes_updated';

  SessionNoteService({this.cloud});

  final CloudSyncService? cloud;

  final Map<int, String> _notes = {};
  Map<int, String> get notes => _notes;

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
    if (cloud != null) {
      final remote = cloud!.getCached('session_notes');
      if (remote != null) {
        final remoteAt = DateTime.tryParse(remote['updatedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localAt = DateTime.tryParse(prefs.getString(_timeKey) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final map = remote['notes'];
          if (map is Map) {
            _notes
              ..clear()
              ..addEntries(map.entries.map((e) => MapEntry(int.parse(e.key), e.value as String)));
            await _persist();
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadSessionNotes(_notes);
        }
      }
    }
    notifyListeners();
  }

  Future<void> setNote(int sessionId, String note) async {
    _notes[sessionId] = note;
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in _notes.entries) e.key.toString(): e.value};
    await prefs.setString(_prefsKey, jsonEncode(data));
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadSessionNotes(_notes);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in _notes.entries) e.key.toString(): e.value};
    await prefs.setString(_prefsKey, jsonEncode(data));
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadSessionNotes(_notes);
    }
  }
}
