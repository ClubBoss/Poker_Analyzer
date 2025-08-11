import 'dart:convert';
import 'dart:io';

/// Tracks summary statistics for automatically generated packs.
class PackGenerationMetricsTrackerService {
  final String _filePath;

  const PackGenerationMetricsTrackerService({
    String filePath = 'autogen_metrics.json',
  }) : _filePath = filePath;

  Future<Map<String, dynamic>> getMetrics() async {
    final file = File(_filePath);
    if (await file.exists()) {
      try {
        final data = jsonDecode(await file.readAsString());
        if (data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data);
        }
      } catch (_) {}
    }
    return {
      'generatedCount': 0,
      'rejectedCount': 0,
      'avgQualityScore': 0.0,
      'lastRunTimestamp': '',
    };
  }

  Future<void> recordGenerationResult({
    required double score,
    required bool accepted,
  }) async {
    final metrics = await getMetrics();
    var generated = (metrics['generatedCount'] as int? ?? 0);
    var rejected = (metrics['rejectedCount'] as int? ?? 0);
    final total = generated + rejected;
    final avg = (metrics['avgQualityScore'] as num?)?.toDouble() ?? 0.0;
    final newAvg = total == 0 ? score : (avg * total + score) / (total + 1);
    if (accepted) {
      generated++;
    } else {
      rejected++;
    }
    metrics
      ..['generatedCount'] = generated
      ..['rejectedCount'] = rejected
      ..['avgQualityScore'] = newAvg
      ..['lastRunTimestamp'] = DateTime.now().toUtc().toIso8601String();
    await _save(metrics);
  }

  Future<void> clearMetrics() async {
    await _save({
      'generatedCount': 0,
      'rejectedCount': 0,
      'avgQualityScore': 0.0,
      'lastRunTimestamp': '',
    });
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final file = File(_filePath);
    await file.writeAsString(jsonEncode(data), flush: true);
  }
}
