import 'package:flutter/material.dart';

class SessionLog {
  final String sessionId;
  final String templateId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int correctCount;
  final int mistakeCount;

  SessionLog({
    required this.sessionId,
    required this.templateId,
    required this.startedAt,
    required this.completedAt,
    required this.correctCount,
    required this.mistakeCount,
  });

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
        sessionId: j['sessionId'] as String? ?? '',
        templateId: j['templateId'] as String? ?? '',
        startedAt:
            DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt:
            DateTime.tryParse(j['completedAt'] as String? ?? '') ?? DateTime.now(),
        correctCount: j['correct'] as int? ?? 0,
        mistakeCount: j['mistakes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'templateId': templateId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'correct': correctCount,
        'mistakes': mistakeCount,
      };
}
