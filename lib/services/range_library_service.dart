import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'range_import_export_service.dart';

class RangeLibraryService {
  RangeLibraryService._([RangeImportExportService? io])
      : _io = io ?? const RangeImportExportService();
  static final instance = RangeLibraryService._();

  final RangeImportExportService _io;

  final Map<String, List<String>> _cache = {};

  Future<List<String>> getRange(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final custom = await _io.readRange(id);
    if (custom != null) {
      _cache[id] = custom;
      return custom;
    }
    try {
      final data = await rootBundle.loadString('assets/ranges/$id.json');
      final list = jsonDecode(data);
      if (list is List) {
        final range = [
          for (final e in list)
            if (e is String) e
        ];
        _cache[id] = range;
        return range;
      }
    } catch (_) {}
    return [];
  }
}
