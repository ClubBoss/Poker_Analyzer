import '../models/validation_issue.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

class TrainingPackTemplateValidator {
  TrainingPackTemplateValidator();

  List<ValidationIssue> validate(TrainingPackTemplateV2 pack) {
    final issues = <ValidationIssue>[];
    void err(String msg) =>
        issues.add(ValidationIssue(type: 'error', message: msg));
    void warn(String msg) =>
        issues.add(ValidationIssue(type: 'warning', message: msg));
    if (pack.id.trim().isEmpty) err('missing_pack_id');
    if (pack.name.trim().isEmpty) err('missing_name');
    if (pack.goal.trim().isEmpty) err('missing_goal');
    if (pack.spots.isEmpty) err('missing_spots');
    if (pack.meta['schemaVersion'] == null) warn('missing_schema_version');
    final tags = <String>{};
    for (final t in pack.tags) {
      final v = t.trim();
      if (v.isEmpty) warn('empty_tag');
      if (!tags.add(v)) warn('duplicate_tag:$v');
    }
    final spotIds = <String>{};
    for (final s in pack.spots) {
      if (s.id.trim().isEmpty) err('missing_spot_id');
      if (!spotIds.add(s.id)) err('duplicate_spot_id:${s.id}');
      final hand = s.hand;
      if (hand.heroIndex < 0 || hand.heroIndex >= hand.playerCount) {
        err('bad_hero_index:${s.id}');
      }
      final heroStack = hand.stacks['${hand.heroIndex}'];
      if (heroStack == null || heroStack <= 0) {
        err('bad_stacks:${s.id}');
      }
      if (hand.position == HeroPosition.unknown)
        warn('unknown_position:${s.id}');
      for (final list in hand.actions.values) {
        for (final a in list) {
          if (a.street < 0 || a.street > 3) {
            err('bad_street:${s.id}');
          }
          if (a.playerIndex < 0 || a.playerIndex >= hand.playerCount) {
            err('bad_action_player:${s.id}');
          }
        }
      }
      final eval = s.evalResult;
      if (eval != null) {
        if (eval.userEquity.isNaN ||
            eval.userEquity < 0 ||
            eval.userEquity > 1) {
          warn('bad_user_equity:${s.id}');
        }
        if (eval.expectedEquity.isNaN ||
            eval.expectedEquity < 0 ||
            eval.expectedEquity > 1) {
          warn('bad_expected_equity:${s.id}');
        }
        if (eval.ev != null &&
            (eval.ev!.isNaN || eval.ev! < -100 || eval.ev! > 100)) {
          warn('bad_ev:${s.id}');
        }
        if (eval.icmEv != null &&
            (eval.icmEv!.isNaN || eval.icmEv! < -100 || eval.icmEv! > 100)) {
          warn('bad_icm_ev:${s.id}');
        }
      }
    }
    return issues;
  }
}
