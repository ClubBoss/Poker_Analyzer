import 'dart:convert';

/// Restores tag mastery data from a JSON export.
class TagMasteryImporter {
  /// Parses [jsonString] exported by [MasteryExportService] and returns a
  /// sanitized tag mastery map.
  ///
  /// Invalid or out-of-range entries are ignored and remaining values are
  /// clamped to the [0.0, 1.0] range. If parsing fails an empty map is
  /// returned.
  Map<String, double> importFromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map) return {};
      final tags = data['tags'];
      if (tags is! Map) return {};
      final result = <String, double>{};
      for (final entry in tags.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        if (key.isEmpty) continue;
        final value = entry.value;
        double? v;
        if (value is num) {
          v = value.toDouble();
        } else if (value is String) {
          v = double.tryParse(value);
        }
        if (v == null || v.isNaN || v.isInfinite) continue;
        result[key] = v.clamp(0.0, 1.0);
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}
