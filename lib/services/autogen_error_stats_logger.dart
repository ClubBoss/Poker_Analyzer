import 'autogen_pack_error_classifier_service.dart';

/// Tracks counts of different [AutogenPackErrorType] occurrences.
class AutogenErrorStatsLogger {
  AutogenErrorStatsLogger._();

  static final AutogenErrorStatsLogger _instance =
      AutogenErrorStatsLogger._();

  /// Shared singleton instance.
  factory AutogenErrorStatsLogger() => _instance;

  /// Accessor for the shared singleton instance.
  static AutogenErrorStatsLogger get instance => _instance;

  final Map<AutogenPackErrorType, int> _counts = {};

  /// Records an [errorType] occurrence.
  void log(AutogenPackErrorType errorType) {
    _counts[errorType] = (_counts[errorType] ?? 0) + 1;
  }

  /// Clears all recorded counts.
  void clear() {
    _counts.clear();
  }

  /// Returns an immutable view of the recorded counts.
  Map<AutogenPackErrorType, int> get counts => Map.unmodifiable(_counts);

  /// Exports the current error counts to CSV format.
  ///
  /// The first line is a header `error_type,count`. Each subsequent line lists
  /// an [AutogenPackErrorType] name and its associated count. Types with no
  /// recorded occurrences are included with a count of zero.
  String exportCsv() {
    final buffer = StringBuffer('error_type,count\n');
    for (final type in AutogenPackErrorType.values) {
      final count = _counts[type] ?? 0;
      buffer.writeln('${type.name},$count');
    }
    return buffer.toString();
  }
}
