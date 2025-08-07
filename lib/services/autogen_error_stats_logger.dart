import 'autogen_pack_error_classifier_service.dart';

/// Tracks counts of different [AutogenPackErrorType] occurrences.
class AutogenErrorStatsLogger {
  final Map<AutogenPackErrorType, int> _counts = {};

  /// Records an [errorType] occurrence.
  void log(AutogenPackErrorType errorType) {
    _counts[errorType] = (_counts[errorType] ?? 0) + 1;
  }

  /// Returns an immutable view of the recorded counts.
  Map<AutogenPackErrorType, int> get counts => Map.unmodifiable(_counts);
}
