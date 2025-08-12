import 'learning_path_telemetry.dart';

/// Records the outcome of an inline recall prompt.
Future<void> recordInlineRecallOutcome({
  required String stage,
  required String tag,
  required bool correct,
}) async {
  try {
    await LearningPathTelemetry.instance.log('inline_recall_outcome', {
      'stage': stage,
      'tag': tag,
      'correct': correct,
    });
  } catch (_) {
    // Aggregation is handled by tool scripts; ignore failures.
  }
}
