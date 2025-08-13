import '../models/yaml_pack_validation_report.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

class YamlPackValidatorService {
  const YamlPackValidatorService();

  YamlPackValidationReport validate(TrainingPackTemplateV2 pack) {
    final errors = <String>[];
    final warnings = <String>[];
    final spotIds = <String>{};
    if (pack.id.trim().isEmpty) errors.add('missing_pack_id');
    if (pack.spots.isEmpty) errors.add('missing_spots');
    if (pack.tags.isEmpty) warnings.add('missing_tags');
    if (pack.meta.isEmpty) warnings.add('missing_meta');
    if (pack.bb <= 0 || pack.bb > 200) warnings.add('bad_bb:${pack.bb}');
    if (pack.positions.isEmpty) warnings.add('missing_positions');
    for (final p in pack.positions) {
      if (parseHeroPosition(p) == HeroPosition.unknown) {
        warnings.add('bad_position:$p');
      }
    }
    for (final s in pack.spots) {
      if (!spotIds.add(s.id)) errors.add('duplicate_id:${s.id}');
      if ((s.explanation ?? '').trim().isEmpty) {
        warnings.add('missing_explanation:${s.id}');
      }
    }
    return YamlPackValidationReport(
      errors: errors,
      warnings: warnings,
      isValid: errors.isEmpty,
    );
  }
}
