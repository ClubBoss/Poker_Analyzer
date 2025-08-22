import 'package:flutter/services.dart' show rootBundle;
import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

typedef ValidationIssue = ({String file, String message});

class PackLibraryValidatorService {
  PackLibraryValidatorService();

  Future<List<ValidationIssue>> validateAll({required String audience}) async {
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys.where(
      (p) => p.startsWith('assets/packs/') && p.toLowerCase().endsWith('.yaml'),
    );
    if (paths.isEmpty) return [];
    const reader = YamlReader();
    final ids = <String, String>{};
    final issues = <ValidationIssue>[];
    for (final path in paths) {
      try {
        final yaml = await rootBundle.loadString(path);
        final map = reader.read(yaml);
        final tpl = TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(map),
        );
        final id = tpl.id.trim();
        if (id.isEmpty) {
          issues.add((file: path, message: 'empty_id'));
        } else {
          final prev = ids[id];
          if (prev != null) {
            issues.add((file: path, message: 'duplicate_id'));
            issues.add((file: prev, message: 'duplicate_id'));
          } else {
            ids[id] = path;
          }
        }
        if (tpl.name.trim().isEmpty) {
          issues.add((file: path, message: 'empty_name'));
        }
        if (tpl.tags.isEmpty) {
          issues.add((file: path, message: 'missing_tags'));
        }
        final heroPos = tpl.positions.isNotEmpty
            ? parseHeroPosition(tpl.positions.first)
            : HeroPosition.unknown;
        if (heroPos == HeroPosition.unknown) {
          issues.add((file: path, message: 'missing_hero_position'));
        }
        final aud = tpl.audience;
        if (aud != null &&
            aud.trim().isNotEmpty &&
            aud.toLowerCase() != audience.toLowerCase()) {
          issues.add((file: path, message: 'audience_mismatch'));
        }
      } catch (_) {
        issues.add((file: path, message: 'parse_error'));
      }
    }
    return issues;
  }
}
