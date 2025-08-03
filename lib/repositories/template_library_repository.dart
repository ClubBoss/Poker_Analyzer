import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:poker_analyzer/asset_manifest.dart';
import 'package:poker_analyzer/models/training_pack_template.dart';
import 'package:poker_analyzer/services/bulk_evaluator_service.dart';
import 'package:poker_analyzer/services/pack_library_loader_service.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';
import 'package:poker_analyzer/utils/template_coverage_utils.dart';

/// Repository responsible for loading template data for the library screen.
class TemplateLibraryRepository {
  TemplateLibraryRepository(this._storage);

  final TemplateStorageService _storage;

  /// Loads template library from persistent storage.
  Future<void> loadLibrary() {
    return PackLibraryLoaderService.instance.loadLibrary();
  }

  /// Imports built-in templates shipped with the app.
  ///
  /// Returns the number of templates added.
  Future<int> importInitialTemplates() async {
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((e) => e.startsWith('assets/templates/initial/') && e.endsWith('.json'));
    var added = 0;
    for (final p in paths) {
      final data = jsonDecode(await rootBundle.loadString(p)) as Map<String, dynamic>;
      final tpl = TrainingPackTemplate.fromJson(data);
      tpl.isBuiltIn = true;
      await BulkEvaluatorService().generateMissing(tpl);
      TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
      _storage.addTemplate(tpl);
      added++;
    }
    return added;
  }
}

