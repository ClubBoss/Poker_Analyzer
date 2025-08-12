import 'dart:io';
import 'package:path/path.dart' as p;

/// Simple CSV writer/aggregator for inline recall accuracy.
class RecallAccuracyAggregator {
  RecallAccuracyAggregator({Directory? root})
    : root = root ?? Directory('build/metrics');

  final Directory root;

  File _file(String stage) => File(
    p.join(
      root.path,
      'recall_'
      '$stage.csv',
    ),
  );

  /// Appends a single outcome entry.
  Future<void> record({
    required String stage,
    required String tag,
    required bool correct,
  }) async {
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    final file = _file(stage);
    final exists = file.existsSync();
    final sink = file.openWrite(mode: FileMode.append);
    if (!exists) {
      sink.writeln('tag,correct');
    }
    sink.writeln('$tag,${correct ? 1 : 0}');
    await sink.close();
  }

  /// Aggregates a CSV file into a human readable summary.
  String summarize(String stage) {
    final file = _file(stage);
    if (!file.existsSync()) return '';
    final lines = file.readAsLinesSync().skip(1);
    var total = 0;
    var ok = 0;
    for (final line in lines) {
      final parts = line.split(',');
      if (parts.length < 2) continue;
      total++;
      if (parts[1].trim() == '1') ok++;
    }
    if (total == 0) return '';
    final pct = (ok / total * 100).toStringAsFixed(1);
    return 'inline_recall_accuracy($stage): $pct% ($ok/$total)';
  }
}
