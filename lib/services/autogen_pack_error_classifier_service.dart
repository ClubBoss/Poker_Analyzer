import 'package:flutter/foundation.dart';

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

/// Detailed record of a rejected pack.
class AutogenPackErrorEntry {
  final DateTime timestamp;
  final String packId;
  final AutogenPackErrorType type;
  final String message;

  AutogenPackErrorEntry({
    required this.timestamp,
    required this.packId,
    required this.type,
    required this.message,
  });
}

/// Classifies rejected packs into [AutogenPackErrorType] categories.
class AutogenPackErrorClassifierService {
  AutogenPackErrorClassifierService();

  static const int _maxErrors = 50;
  static final ValueNotifier<List<AutogenPackErrorEntry>> _recentErrors =
      ValueNotifier<List<AutogenPackErrorEntry>>([]);

  /// Returns the [AutogenPackErrorType] for a rejected [pack] and optional
  /// generation [error]. Logs the classification for later inspection.
  AutogenPackErrorType classify(TrainingPackTemplateV2 pack, Exception? error) {
    final msg = error?.toString().toLowerCase() ?? '';
    AutogenPackErrorType type;
    if (msg.contains('duplicate')) {
      type = AutogenPackErrorType.duplicate;
    } else if (msg.contains('empty')) {
      type = AutogenPackErrorType.emptyOutput;
    } else if (msg.contains('invalid board')) {
      type = AutogenPackErrorType.invalidBoard;
    } else if (msg.contains('syntax') || msg.contains('format')) {
      type = AutogenPackErrorType.templateSyntaxError;
    } else if (pack.spots.isEmpty || pack.spotCount == 0) {
      type = AutogenPackErrorType.noSpotsGenerated;
    } else {
      type = AutogenPackErrorType.unknown;
    }

    final entry = AutogenPackErrorEntry(
      timestamp: DateTime.now(),
      packId: pack.name.isNotEmpty ? pack.name : pack.id,
      type: type,
      message: error?.toString() ?? '',
    );
    final list = List<AutogenPackErrorEntry>.from(_recentErrors.value)
      ..add(entry);
    if (list.length > _maxErrors) {
      list.removeRange(0, list.length - _maxErrors);
    }
    _recentErrors.value = list;

    return type;
  }

  /// Returns a listenable of recent classified errors.
  static ValueListenable<List<AutogenPackErrorEntry>>
  recentErrorsListenable() => _recentErrors;

  /// Returns the current recent error list.
  static List<AutogenPackErrorEntry> getRecentErrors() =>
      List.unmodifiable(_recentErrors.value);

  /// Clears the recent error log.
  static void clearRecentErrors() => _recentErrors.value = [];
}
