import 'package:flutter/material.dart';

class DrillResult {
  final String templateId;
  final String templateName;
  final DateTime date;
  final int total;
  final int correct;
  final double evLoss;
  final List<String> wrongSpotIds;
  DrillResult({
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.total,
    required this.correct,
    required this.evLoss,
    List<String>? wrongSpotIds,
  }) : wrongSpotIds = wrongSpotIds ?? [];

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'templateName': templateName,
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'evLoss': evLoss,
        if (wrongSpotIds.isNotEmpty) 'wrongSpotIds': wrongSpotIds,
      };

  factory DrillResult.fromJson(Map<String, dynamic> j) => DrillResult(
        templateId: j['templateId'] as String? ?? '',
        templateName: j['templateName'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        total: j['total'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        evLoss: (j['evLoss'] as num?)?.toDouble() ?? 0.0,
        wrongSpotIds: [for (final id in (j['wrongSpotIds'] as List? ?? [])) id as String],
      );
}
