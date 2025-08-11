import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fingerprint describing a single training session.
class TrainingSessionFingerprint {
  /// Unique identifier for the session.
  final String sessionId;

  /// ID of the training pack played in this session.
  final String packId;

  /// Timestamp when the session started.
  final DateTime startTime;

  /// Timestamp when the session ended.
  final DateTime endTime;

  /// Tags covered during the session.
  final List<String> tagsCovered;

  /// Optional device identifier.
  final String? deviceId;

  /// Additional metrics retained for backwards compatibility.
  final int totalSpots;
  final int correct;
  final int incorrect;

  TrainingSessionFingerprint({
    required this.packId,
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? tagsCovered,
    List<String>? tags,
    DateTime? completedAt,
    this.deviceId,
    this.totalSpots = 0,
    this.correct = 0,
    this.incorrect = 0,
  })  : startTime = startTime ?? endTime ?? completedAt ?? DateTime.now(),
        endTime = endTime ?? completedAt ?? DateTime.now(),
        sessionId = sessionId ?? _generateSessionId(packId),
        tagsCovered = tagsCovered ?? tags ?? const [];

  /// Legacy accessor for [tagsCovered].
  List<String> get tags => tagsCovered;

  /// Legacy accessor for [endTime].
  DateTime get completedAt => endTime;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'packId': packId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'tagsCovered': tagsCovered,
        if (deviceId != null) 'deviceId': deviceId,
        'totalSpots': totalSpots,
        'correct': correct,
        'incorrect': incorrect,
      };

  factory TrainingSessionFingerprint.fromJson(Map<String, dynamic> json) {
    return TrainingSessionFingerprint(
      sessionId: json['sessionId'] as String?,
      packId: json['packId'] as String? ?? '',
      startTime:
          DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      tagsCovered: [
        for (final t in (json['tagsCovered'] as List? ?? [])) t.toString()
      ],
      deviceId: json['deviceId']?.toString(),
      totalSpots: json['totalSpots'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      incorrect: json['incorrect'] as int? ?? 0,
    );
  }
}

/// Service responsible for recording and retrieving [TrainingSessionFingerprint]
/// entries. Fingerprints are persisted in [SharedPreferences].
class TrainingSessionFingerprintLoggerService {
  TrainingSessionFingerprintLoggerService({SharedPreferences? prefs})
      : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'training_session_fingerprints';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Begins logging a session for [packId].
  Future<void> logSessionStart(String packId, {String? deviceId}) async {
    final fp = TrainingSessionFingerprint(packId: packId, deviceId: deviceId);
    await _upsertFingerprint(fp);
    debugPrint('Session start logged for $packId');
  }

  /// Completes logging for the most recent session of [packId] and records
  /// [tagsCovered].
  Future<void> logSessionEnd(String packId, List<String> tagsCovered) async {
    final sessions = await getAllSessions();
    for (var i = sessions.length - 1; i >= 0; i--) {
      final s = sessions[i];
      if (s.packId == packId && s.tagsCovered.isEmpty) {
        sessions[i] = TrainingSessionFingerprint(
          packId: s.packId,
          sessionId: s.sessionId,
          startTime: s.startTime,
          endTime: DateTime.now(),
          tagsCovered: tagsCovered,
          deviceId: s.deviceId,
          totalSpots: s.totalSpots,
          correct: s.correct,
          incorrect: s.incorrect,
        );
        await _saveAll(sessions);
        debugPrint('Session end logged for $packId');
        return;
      }
    }
    // If no matching start found, log a complete session directly.
    await logSession(
      TrainingSessionFingerprint(
        packId: packId,
        tagsCovered: tagsCovered,
      ),
    );
  }

  /// Convenience method to log a fully formed [TrainingSessionFingerprint].
  Future<void> logSession(TrainingSessionFingerprint fp) async {
    final sessions = await getAllSessions();
    sessions.add(fp);
    await _saveAll(sessions);
    debugPrint('Logged training session fingerprint for ${fp.packId}');
  }

  /// Returns all recorded sessions.
  Future<List<TrainingSessionFingerprint>> getAllSessions() async {
    final prefs = await _sp;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map)
            TrainingSessionFingerprint.fromJson(
                Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Legacy alias for [getAllSessions].
  Future<List<TrainingSessionFingerprint>> getAll() => getAllSessions();

  /// Removes all logged fingerprints.
  Future<void> clear() async {
    final prefs = await _sp;
    await prefs.remove(_key);
  }

  Future<void> _upsertFingerprint(TrainingSessionFingerprint fp) async {
    final sessions = await getAllSessions();
    sessions.add(fp);
    await _saveAll(sessions);
  }

  Future<void> _saveAll(List<TrainingSessionFingerprint> list) async {
    final prefs = await _sp;
    await prefs.setString(
      _key,
      jsonEncode([for (final s in list) s.toJson()]),
    );
  }
}

String _generateSessionId(String packId) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final hash = ts.hashCode & 0x7fffffff;
  return '${packId}_${hash.toString()}';
}
