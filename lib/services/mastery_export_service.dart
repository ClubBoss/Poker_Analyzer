import 'dart:convert';

/// Converts tag mastery data into a portable JSON format.
class MasteryExportService {
  /// Returns a JSON string representing [tagMastery].
  ///
  /// - Entries are sorted alphabetically by tag.
  /// - Values are rounded to 3 decimal places.
  /// - Only entries within [0.0, 1.0] are included.
  /// - Metadata fields `schemaVersion` and `exportedAt` are added.
  String exportToJson(Map<String, double> tagMastery) {
    final filtered = <String, double>{};
    tagMastery.forEach((tag, value) {
      if (value.isFinite && value >= 0.0 && value <= 1.0) {
        final key = tag.trim();
        if (key.isNotEmpty) {
          final rounded = ((value * 1000).round() / 1000);
          filtered[key] = rounded;
        }
      }
    });

    final sortedKeys = filtered.keys.toList()..sort();
    final sortedMap = {for (final k in sortedKeys) k: filtered[k]};

    final data = {
      'schemaVersion': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': sortedMap,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
