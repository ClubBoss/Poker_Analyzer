import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionResume {
  static const _key = 'resume_session_v1';

  static Future<void> save({
    required String packId,
    required int index,
    required String sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final obj = jsonEncode({
      'schema': 1,
      'packId': packId,
      'index': index,
      'sessionId': sessionId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    await prefs.setString(_key, obj);
  }

  static Future<({String packId, int index, String sessionId})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final obj = jsonDecode(raw);
      if (obj is Map && obj['schema'] == 1) {
        final packId = obj['packId'];
        final index = obj['index'];
        final sessionId = obj['sessionId'];
        if (packId is String && index is int && sessionId is String) {
          return (packId: packId, index: index, sessionId: sessionId);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
