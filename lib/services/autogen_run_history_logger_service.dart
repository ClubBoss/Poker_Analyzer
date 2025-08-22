import 'dart:convert';
import 'dart:io';

import '../models/training_run_record.dart';

class RunMetricsEntry {
  final DateTime timestamp;
  final int generated;
  final int rejected;
  final double avgQualityScore;
  final FormatMeta? format;

  RunMetricsEntry({
    required this.timestamp,
    required this.generated,
    required this.rejected,
    required this.avgQualityScore,
    this.format,
  });

  factory RunMetricsEntry.fromJson(Map<String, dynamic> json) =>
      RunMetricsEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        generated: json['generated'] as int,
        rejected: json['rejected'] as int,
        avgQualityScore: (json['avgQualityScore'] as num).toDouble(),
        format: json['format'] is Map<String, dynamic>
            ? FormatMeta.fromJson(json['format'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'generated': generated,
    'rejected': rejected,
    'avgQualityScore': avgQualityScore,
    if (format != null) 'format': format!.toJson(),
  };

  double get acceptanceRate {
    final total = generated + rejected;
    if (total == 0) return 0;
    return generated / total * 100;
  }
}

class AutogenRunHistoryLoggerService {
  final String _filePath;

  AutogenRunHistoryLoggerService({
    String filePath = 'autogen_run_history.json',
  }) : _filePath = filePath;

  Future<void> logRun({
    required int generated,
    required int rejected,
    required double avgScore,
    FormatMeta? format,
  }) async {
    final entries = await getHistory();
    entries.add(
      RunMetricsEntry(
        timestamp: DateTime.now().toUtc(),
        generated: generated,
        rejected: rejected,
        avgQualityScore: avgScore,
        format: format,
      ),
    );
    final file = File(_filePath);
    await file.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Future<List<RunMetricsEntry>> getHistory() async {
    final file = File(_filePath);
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(RunMetricsEntry.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
