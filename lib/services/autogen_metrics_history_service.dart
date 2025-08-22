import 'dart:convert';
import 'dart:io';

class RunMetricsEntry {
  final DateTime timestamp;
  final double avgQualityScore;
  final double acceptanceRate;

  RunMetricsEntry({
    required this.timestamp,
    required this.avgQualityScore,
    required this.acceptanceRate,
  });

  factory RunMetricsEntry.fromJson(Map<String, dynamic> json) {
    return RunMetricsEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      avgQualityScore: (json['avgQualityScore'] as num).toDouble(),
      acceptanceRate: (json['acceptanceRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'avgQualityScore': avgQualityScore,
    'acceptanceRate': acceptanceRate,
  };
}

class AutogenMetricsHistoryService {
  final String _filePath;

  AutogenMetricsHistoryService({
    String filePath = 'autogen_metrics_history.json',
  }) : _filePath = filePath;

  Future<void> recordRunMetrics(
    double avgQuality,
    double acceptanceRate,
  ) async {
    final file = File(_filePath);
    final entries = await loadHistory();
    entries.add(
      RunMetricsEntry(
        timestamp: DateTime.now().toUtc(),
        avgQualityScore: avgQuality,
        acceptanceRate: acceptanceRate,
      ),
    );
    await file.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Future<List<RunMetricsEntry>> loadHistory() async {
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

  /// Returns the two most recent [RunMetricsEntry] items, newest first.
  Future<List<RunMetricsEntry>> getLastTwoRuns() async {
    final history = await loadHistory();
    final reversed = history.reversed.toList();
    return reversed.take(2).toList();
  }
}
