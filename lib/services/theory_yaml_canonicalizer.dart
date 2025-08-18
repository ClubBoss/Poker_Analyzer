// lib/services/theory_yaml_canonicalizer.dart
import 'dart:convert';

/// Canonicalizes YAML data represented as a Map for deterministic hashing.
class TheoryYamlCanonicalizer {
  const TheoryYamlCanonicalizer();

  /// Returns a stable JSON string representation of [data].
  ///
  /// Maps have their keys recursively sorted. Scalar values are normalized
  /// via [jsonEncode] and lists preserve their original order.
  String canonicalize(Map<String, dynamic> data) {
    final canonical = _canon(data);
    return jsonEncode(canonical);
  }

  dynamic _canon(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      return {for (final k in keys) k: _canon(value[k])};
    } else if (value is List) {
      return value.map(_canon).toList();
    } else if (value is num || value is bool || value == null) {
      return value;
    } else {
      return value.toString();
    }
  }
}
