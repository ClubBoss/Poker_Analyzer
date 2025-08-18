import 'dart:io';

import '../models/pack_library.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/generation/yaml_reader.dart';
import 'pack_library_loader_service.dart';
import 'theory_export_validator.dart';

/// Automatically uploads validated theory packs into the staging library.
class BoosterPackAutoUploader {
  const BoosterPackAutoUploader();

  /// Loads all theory YAML files from [dir], validates them and imports
  /// valid packs into [PackLibrary.staging].
  ///
  /// Returns the list of imported templates.
  Future<List<TrainingPackTemplateV2>> uploadAll({
    String dir = 'yaml_out/theory',
  }) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final directory = Directory(dir);
    if (!directory.existsSync()) return <TrainingPackTemplateV2>[];

    // Collect validation errors to know which files to skip.
    final validation = await const TheoryExportValidator().validateAll(
      dir: dir,
    );
    final errorsByFile = <String, List<String>>{};
    for (final e in validation) {
      errorsByFile.putIfAbsent(e.$1, () => <String>[]).add(e.$2);
    }
    final skip = <String>{};
    errorsByFile.forEach((path, errs) {
      if (errs.contains('duplicate_id') ||
          errs.contains('parse_error') ||
          errs.any((e) => e.startsWith('bad_trainingType'))) {
        skip.add(path);
      }
    });

    const reader = YamlReader();
    final imported = <TrainingPackTemplateV2>[];
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));

    for (final file in files) {
      if (skip.contains(file.path)) continue;
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(map),
        );
        tpl.meta = Map<String, dynamic>.from(tpl.meta)
          ..['source'] = 'auto_uploaded_theory';
        PackLibrary.staging.add(tpl);
        imported.add(tpl);
      } catch (_) {}
    }

    return imported;
  }
}
