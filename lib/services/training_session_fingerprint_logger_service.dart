import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/engine/training_type_engine.dart';

class TrainingSessionFingerprint {
  final String fingerprint;
  final String packId;
  final TrainingType trainingType;
  final int spotCount;
  final double accuracy;
  final DateTime completedAt;

  TrainingSessionFingerprint({
    required this.fingerprint,
    required this.packId,
    required this.trainingType,
    required this.spotCount,
    required this.accuracy,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'packId': packId,
        'trainingType': trainingType.name,
        'spotCount': spotCount,
        'accuracy': accuracy,
        'completedAt': completedAt.toIso8601String(),
      };

  factory TrainingSessionFingerprint.fromJson(Map<String, dynamic> json) {
    return TrainingSessionFingerprint(
      fingerprint: json['fingerprint'] as String,
      packId: json['packId'] as String,
      trainingType: TrainingType.values.firstWhere(
        (e) => e.name == json['trainingType'],
        orElse: () => TrainingType.custom,
      ),
      spotCount: json['spotCount'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class TrainingSessionFingerprintLoggerService {
  TrainingSessionFingerprintLoggerService({SharedPreferences? prefs})
      : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _prefix = 'session_fingerprint_';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> logSession(TrainingSessionFingerprint session) async {
    final prefs = await _sp;
    await prefs.setString(
      '$_prefix${session.fingerprint}',
      jsonEncode(session.toJson()),
    );
  }

  Future<List<TrainingSessionFingerprint>> getAll() async {
    final prefs = await _sp;
    final list = <TrainingSessionFingerprint>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final data = jsonDecode(raw);
          if (data is Map<String, dynamic>) {
            list.add(
              TrainingSessionFingerprint.fromJson(
                Map<String, dynamic>.from(data),
              ),
            );
          }
        } catch (_) {}
      }
    }
    return list;
  }
}
