import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/v2/training_pack_template.dart';
import '../utils/template_coverage_utils.dart';
import '../services/training_pack_author_service.dart';

class TrainingPackStorage {
  static const _key = 'training_pack_templates';

  static const _presetIds = [
    '10bb_co_vs_bb',
    '10bb_sb_vs_bb',
    '15bb_hj_vs_bb',
    '25bb_co_vs_btn_3bet',
    'icm_final_table_6max_12bb_co',
  ];

  static Future<List<TrainingPackTemplate>> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final generated = [
        for (final id in _presetIds)
          TrainingPackAuthorService.generateFromPreset(id)
      ];
      await save(generated);
      return generated;
    }
    final list = jsonDecode(raw) as List;
    if (list.isEmpty) {
      final generated = [
        for (final id in _presetIds)
          TrainingPackAuthorService.generateFromPreset(id)
      ];
      await save(generated);
      return generated;
    }
    final templates = [for (final m in list) TrainingPackTemplate.fromJson(m)];
    bool changed = false;
    for (final t in templates) {
      if (!t.meta.containsKey('evCovered') || !t.meta.containsKey('icmCovered')) {
        TemplateCoverageUtils.recountAll(t).applyTo(t.meta);
        changed = true;
      }
    }
    if (changed) await save(templates);
    return templates;
  }

  static Future<void> save(List<TrainingPackTemplate> t) async {
    for (final tpl in t) {
      TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    }
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_key, jsonEncode([for (final x in t) x.toJson()]));
  }

  static Future<Directory> previewImageDir(TrainingPackTemplate t) async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/template_previews/${t.id}');
  }
}
