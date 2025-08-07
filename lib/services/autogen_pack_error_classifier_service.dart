import '../models/v2/training_pack_template_v2.dart';

/// Enumerates known auto-generation error types for packs.
enum AutogenPackErrorType {
  duplicate,
  emptyOutput,
  invalidBoard,
  noSpotsGenerated,
  templateSyntaxError,
  unknown,
}

/// Classifies rejected packs into [AutogenPackErrorType] categories.
class AutogenPackErrorClassifierService {
  const AutogenPackErrorClassifierService();

  /// Returns the [AutogenPackErrorType] for a rejected [pack] and optional
  /// generation [error].
  AutogenPackErrorType classify(TrainingPackTemplateV2 pack, Exception? error) {
    final msg = error?.toString().toLowerCase() ?? '';
    if (msg.contains('duplicate')) return AutogenPackErrorType.duplicate;
    if (msg.contains('empty')) return AutogenPackErrorType.emptyOutput;
    if (msg.contains('invalid board')) return AutogenPackErrorType.invalidBoard;
    if (msg.contains('syntax') || msg.contains('format')) {
      return AutogenPackErrorType.templateSyntaxError;
    }
    if (pack.spots.isEmpty || pack.spotCount == 0) {
      return AutogenPackErrorType.noSpotsGenerated;
    }
    return AutogenPackErrorType.unknown;
  }
}
