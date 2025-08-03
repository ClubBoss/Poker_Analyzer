import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

class TrainingPackCommentsService {
  TrainingPackCommentsService._();
  static final instance = TrainingPackCommentsService._();

  static const _prefsKey = 'pack_comments';
  Map<String, String> _comments = {};

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _comments = {
            for (final e in data.entries) e.key.toString(): e.value.toString()
          };
        }
      } catch (_) {
        _comments = {};
      }
    }
  }

  Future<void> saveComment(String packId, String comment) async {
    _comments[packId] = comment;
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_comments));
  }

  Future<String?> getComment(String packId) async {
    return _comments[packId];
  }
}
