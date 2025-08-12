import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_service.dart';

/// Handles seeding of built-in starter packs on first launch.
class BuiltInPackBootstrapService {
  const BuiltInPackBootstrapService({
    PackLibraryService? library,
    SharedPreferences? prefs,
  })  : _library = library ?? PackLibraryService.instance,
        _prefs = prefs;

  final PackLibraryService _library;
  final SharedPreferences? _prefs;

  /// Current bootstrap version.
  static const int _version = 2;
  static const String _manifestPath = 'assets/packs_builtin/manifest.json';

  Future<void> importIfNeeded() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final key = 'builtinPacksImported:v$_version';
    final already = prefs.getBool(key) ?? false;
    if (_library.count() > 0 && already) return;

    List<dynamic> manifest;
    try {
      final raw = await rootBundle.loadString(_manifestPath);
      final data = jsonDecode(raw);
      if (data is! List) return;
      manifest = data;
    } catch (_) {
      return;
    }

    for (final item in manifest) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      final file = item['file']?.toString();
      if (id == null || file == null) continue;
      try {
        final packRaw =
            await rootBundle.loadString('assets/packs_builtin/$file');
        final map = jsonDecode(packRaw) as Map<String, dynamic>;
        final tpl = TrainingPackTemplateV2.fromJson(map);
        _library.addOrUpdate(tpl);
      } catch (_) {
        // Swallow errors to avoid blocking startup
      }
    }

    await prefs.setBool(key, true);
  }
}
