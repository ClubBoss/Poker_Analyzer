import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RangeLibraryService {
  RangeLibraryService._();
  static final instance = RangeLibraryService._();

  final Map<String, List<String>> _cache = {};

  Future<List<String>> getRange(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.loadString('assets/ranges/$id.json');
      final list = jsonDecode(data);
      if (list is List) {
        final range = [for (final e in list) if (e is String) e];
        _cache[id] = range;
        return range;
      }
    } catch (_) {}
    return [];
  }
}
