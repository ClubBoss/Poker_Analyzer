import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingSessionFingerprint {
  final String packId;
  final List<String> tags;
  final DateTime completedAt;
  final int totalSpots;
  final int correct;
  final int incorrect;

  TrainingSessionFingerprint({
    required this.packId,
    List<String>? tags,
    DateTime? completedAt,
    this.totalSpots = 0,
    this.correct = 0,
    this.incorrect = 0,
  })  : tags = tags ?? const [],
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'tags': tags,
        'completedAt': completedAt.toIso8601String(),
        'totalSpots': totalSpots,
        'correct': correct,
        'incorrect': incorrect,
      };

  factory TrainingSessionFingerprint.fromJson(Map<String, dynamic> json) {
    return TrainingSessionFingerprint(
      packId: json['packId'] as String? ?? '',
      tags: [for (final t in (json['tags'] as List? ?? [])) t.toString()],
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      totalSpots: json['totalSpots'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      incorrect: json['incorrect'] as int? ?? 0,
    );
  }
}

class TrainingSessionFingerprintLoggerService {
  TrainingSessionFingerprintLoggerService({SharedPreferences? prefs})
      : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'training_session_fingerprints';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> logSession(TrainingSessionFingerprint fp) async {
    final prefs = await _sp;
    final raw = prefs.getString(_key);
    List<dynamic> list;
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        list = [];
      }
    } else {
      list = [];
    }
    list.add(fp.toJson());
    await prefs.setString(_key, jsonEncode(list));
    debugPrint('Logged training session fingerprint for ${fp.packId}');
  }

  Future<List<TrainingSessionFingerprint>> getAll() async {
    final prefs = await _sp;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map)
            TrainingSessionFingerprint.fromJson(
                Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await _sp;
    await prefs.remove(_key);
  }
}
