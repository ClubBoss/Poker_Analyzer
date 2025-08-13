import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/training_spot_attempt.dart';
import '../models/spot_attempt_summary.dart';

class TrainingSessionFingerprintService {
  static const _storageKey = 'training_session_fingerprints';
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  Future<String> startSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = const Uuid().v4();
    final sessions = _loadSessions(prefs);
    sessions.add({
      'sessionId': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': <Map<String, dynamic>>[],
    });
    await prefs.setString(_storageKey, jsonEncode(sessions));
    return _currentSessionId!;
  }

  Future<void> logAttempt(TrainingSpotAttempt attempt,
      {List<String> shownTheoryTags = const []}) async {
    if (_currentSessionId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final sessions = _loadSessions(prefs);
    final idx = sessions.indexWhere((e) => e['sessionId'] == _currentSessionId);
    if (idx == -1) return;
    final summary = SpotAttemptSummary(
      spotId: attempt.spot.id,
      userAction: attempt.userAction,
      isCorrect: attempt.userAction.toLowerCase() ==
          attempt.correctAction.toLowerCase(),
      evDiff: attempt.evDiff,
      shownTheoryTags: shownTheoryTags,
    ).toJson();
    final attempts =
        List<Map<String, dynamic>>.from(sessions[idx]['attempts'] as List);
    attempts.add(summary);
    sessions[idx]['attempts'] = attempts;
    await prefs.setString(_storageKey, jsonEncode(sessions));
  }

  Future<Map<String, dynamic>?> getSessionSummary(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = _loadSessions(prefs);
    return sessions.firstWhere(
      (e) => e['sessionId'] == id,
      orElse: () => null,
    );
  }

  Future<List<Map<String, dynamic>>> getSessionsByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = _loadSessions(prefs);
    final target = DateTime(date.year, date.month, date.day);
    final result = <Map<String, dynamic>>[];
    for (final s in sessions) {
      final ts = DateTime.tryParse(s['timestamp'] ?? '');
      if (ts == null) continue;
      final d = DateTime(ts.year, ts.month, ts.day);
      if (d == target) result.add(s);
    }
    return result;
  }

  List<Map<String, dynamic>> _loadSessions(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map) Map<String, dynamic>.from(e) else {},
      ];
    } catch (_) {
      return [];
    }
  }
}
