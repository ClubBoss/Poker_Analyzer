import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

/// Lints booster packs and returns list of formatted error messages.
class BoosterPackLinterEngine {
  BoosterPackLinterEngine();

  /// Returns list of errors in "- [id] Ошибка: ..." format.
  List<String> lint(TrainingPackTemplateV2 pack) {
    final errs = <String>[];
    final ids = <String>{};
    for (final s in pack.spots) {
      if (!ids.add(s.id)) {
        errs.add('- [${s.id}] Ошибка: duplicate_id');
      }
      if (s.explanation == null || s.explanation!.trim().isEmpty) {
        errs.add('- [${s.id}] Ошибка: empty_explanation');
      }
      if (s.hand.heroCards.trim().isEmpty) {
        errs.add('- [${s.id}] Ошибка: empty_heroCards');
      }
      final hasActions = s.hand.actions.values.any((l) => l.isNotEmpty);
      if (!hasActions) {
        errs.add('- [${s.id}] Ошибка: empty_actions');
      }
      if (s.hand.position == HeroPosition.unknown) {
        errs.add('- [${s.id}] Ошибка: bad_heroPosition');
      }
      if (s.tags.isEmpty) {
        errs.add('- [${s.id}] Ошибка: missing_tags');
      }
      final ev = s.heroEv;
      final icm = s.heroIcmEv;
      if ((ev != null && ev == 0) || (icm != null && icm == 0)) {
        errs.add('- [${s.id}] Ошибка: zero_ev');
      }
    }
    return errs;
  }
}
