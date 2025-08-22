import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_health_report.dart';

class TrainingPackHealthReportService {
  TrainingPackHealthReportService();

  Future<TrainingHealthReport> generateReport({
    String path = 'training_packs/library',
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) {
      return const TrainingHealthReport(issues: [], errors: 0, warnings: 0);
    }
    const reader = YamlReader();
    final issues = <(String, String)>[];
    final spotMap = <String, String>{};
    var errors = 0;
    var warnings = 0;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      Map<String, dynamic> map;
      String yaml;
      try {
        yaml = await f.readAsString();
        map = reader.read(yaml);
      } catch (_) {
        issues.add((f.path, 'invalid_yaml'));
        errors++;
        continue;
      }
      TrainingPackTemplateV2 tpl;
      try {
        tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      } catch (_) {
        issues.add((f.path, 'invalid_format'));
        errors++;
        continue;
      }
      if (tpl.id.trim().isEmpty) {
        issues.add((f.path, 'missing_id'));
        errors++;
      }
      if (tpl.audience == null || tpl.audience!.trim().isEmpty) {
        issues.add((f.path, 'missing_audience'));
        warnings++;
      }
      if (tpl.tags.isEmpty) {
        issues.add((f.path, 'missing_tags'));
        warnings++;
      }
      final tagSet = <String>{};
      for (final t in tpl.tags) {
        final trimmed = t.trim();
        if (trimmed.isEmpty || trimmed != t) {
          issues.add((f.path, 'invalid_tag'));
          warnings++;
        }
        final key = trimmed.toLowerCase();
        if (!tagSet.add(key)) {
          issues.add((f.path, 'duplicate_tag'));
          warnings++;
        }
      }
      if (tpl.meta['evScore'] == null) {
        issues.add((f.path, 'missing_evScore'));
        warnings++;
      }
      if (tpl.spots.isEmpty) {
        issues.add((f.path, 'empty_spots'));
        errors++;
      }
      final localIds = <String>{};
      for (final s in tpl.spots) {
        if (!localIds.add(s.id)) {
          issues.add((f.path, 'duplicate_spot'));
          warnings++;
        }
        if (spotMap.containsKey(s.id)) {
          issues.add((f.path, 'duplicate_spot_global'));
          warnings++;
        } else {
          spotMap[s.id] = f.path;
        }
        final hero = s.hand.heroIndex;
        final hasHero = s.hand.actions.values.any(
          (l) => l.any((a) => a.playerIndex == hero),
        );
        if (!hasHero) {
          issues.add((f.path, 'no_hero_action'));
          warnings++;
        }
        if (s.evalResult == null) {
          issues.add((f.path, 'no_evaluation'));
          warnings++;
        }
        final empty =
            s.hand.heroCards.isEmpty &&
            s.hand.board.isEmpty &&
            s.hand.actions.values.every((l) => l.isEmpty);
        if (empty) {
          issues.add((f.path, 'empty_spot'));
          errors++;
        }
      }
    }
    return TrainingHealthReport(
      issues: issues,
      errors: errors,
      warnings: warnings,
    );
  }
}
