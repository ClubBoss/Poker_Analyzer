import '../models/yaml_pack_validation_report.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

class PackValidationEngine {
  PackValidationEngine();

  YamlPackValidationReport validate(TrainingPackTemplateV2 pack) {
    final errors = <String>[];
    final warnings = <String>[];
    if (pack.name.trim().isEmpty) errors.add('missing_name');
    if (pack.goal.trim().isEmpty) errors.add('missing_goal');
    if (pack.description.trim().isEmpty) errors.add('missing_description');
    if (pack.tags.isEmpty) errors.add('missing_tags');
    if (pack.spots.isEmpty) errors.add('missing_spots');
    final ids = <String>{};
    for (final s in pack.spots) {
      if (!ids.add(s.id)) errors.add('duplicate_id:${s.id}');
      if (s.priority < 0 || s.priority > 100)
        warnings.add('bad_priority:${s.id}');
      final ev = s.heroEv;
      if (ev != null && (ev.isNaN || ev < -100 || ev > 100)) {
        warnings.add('bad_ev:${s.id}');
      }
      final icm = s.heroIcmEv;
      if (icm != null && (icm.isNaN || icm < -100 || icm > 100)) {
        warnings.add('bad_icm:${s.id}');
      }
      if (s.hand.position == HeroPosition.unknown) {
        warnings.add('unknown_position:${s.id}');
      }
      if (_heroAction(s) == null) warnings.add('no_action:${s.id}');
    }
    return YamlPackValidationReport(
      errors: errors,
      warnings: warnings,
      isValid: errors.isEmpty,
    );
  }

  String? _heroAction(TrainingPackSpot s) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex) return a.action.toLowerCase();
    }
    return null;
  }
}
