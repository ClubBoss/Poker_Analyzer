import 'dart:convert';
import 'dart:io';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/smart_validation_result.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_auto_fix_engine.dart';
import 'pack_validation_engine.dart';

class PackLibrarySmartValidator {
  PackLibrarySmartValidator();

  Future<SmartValidationResult> validateAndFix(String path) async {
    final file = File(path);
    if (!file.existsSync()) return const SmartValidationResult();
    final yaml = await file.readAsString();
    final map = const YamlReader().read(yaml);
    var tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
    final before = const PackValidationEngine().validate(tpl);
    if (before.errors.isNotEmpty) {
      final fixed = const PackLibraryAutoFixEngine().autoFix(tpl);
      final changed = jsonEncode(fixed.toJson()) != jsonEncode(tpl.toJson());
      if (changed) {
        await const YamlWriter().write(fixed.toJson(), path);
        tpl = fixed;
      }
    }
    final after = const PackValidationEngine().validate(tpl);
    final fixed = <String>[
      for (final e in before.errors)
        if (!after.errors.contains(e)) e,
      for (final w in before.warnings)
        if (!after.warnings.contains(w)) w,
    ];
    return SmartValidationResult(before: before, after: after, fixed: fixed);
  }
}
