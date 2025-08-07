import 'dart:convert';
import 'dart:io';

class RunMetricsEntry {
  final DateTime timestamp;
  final int generated;
  final int rejected;
  final double avgQualityScore;

  RunMetricsEntry({
    required this.timestamp,
    required this.generated,
    required this.rejected,
    required this.avgQualityScore,
  });

  factory RunMetricsEntry.fromJson(Map<String, dynamic> json) =>
      RunMetricsEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        generated: json['generated'] as int,
        rejected: json['rejected'] as int,
        avgQualityScore: (json['avgQualityScore'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'generated': generated,
        'rejected': rejected,
        'avgQualityScore': avgQualityScore,
      };
}

class AutogenRunHistoryLoggerService {
  final String _filePath;

  const AutogenRunHistoryLoggerService({
    String filePath = 'autogen_run_history.json',
  }) : _filePath = filePath;

  Future<void> logRun({
    required int generated,
    required int rejected,
    required double avgScore,
  }) async {
    final entries = await getHistory();
    entries.add(RunMetricsEntry(
      timestamp: DateTime.now().toUtc(),
      generated: generated,
      rejected: rejected,
      avgQualityScore: avgScore,
    ));
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
