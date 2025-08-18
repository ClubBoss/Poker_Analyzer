import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/pack_warning.dart';

class PackLibraryQAEngine {
  const PackLibraryQAEngine();

  List<PackWarning> run(List<TrainingPackTemplateV2> packs) {
    final warnings = <PackWarning>[];
    final ids = <String>{};
    for (final p in packs) {
      if (!ids.add(p.id)) {
        warnings.add(PackWarning('duplicate_id', 'Duplicate id', p.id));
      }
      if (p.spots.isEmpty) {
        warnings.add(PackWarning('empty_spots', 'Pack has no spots', p.id));
      }
      var missingEval = 0;
      var blank = 0;
      for (final s in p.spots) {
        if (s.evalResult == null) missingEval++;
        if (_isEmptySpot(s)) blank++;
      }
      if (missingEval > 0) {
        warnings.add(
          PackWarning(
            'missing_evaluation',
            '$missingEval spots without evaluation',
            p.id,
          ),
        );
      }
      if (blank > 0) {
        warnings.add(PackWarning('blank_spots', '$blank empty spots', p.id));
      }
      if (p.name.trim().length < 3 || p.name.length > 50) {
        warnings.add(PackWarning('bad_name', p.name, p.id));
      }
      final outdated = [
        for (final t in p.tags)
          if (_badTag(t)) t,
      ];
      if (outdated.isNotEmpty) {
        warnings.add(PackWarning('outdated_tags', outdated.join(','), p.id));
      }
      final ev = (p.meta['evScore'] as num?)?.toDouble();
      if (ev != null && ev < 60) {
        warnings.add(PackWarning('low_evScore', ev.toStringAsFixed(1), p.id));
      }
    }
    return warnings;
  }

  bool _isEmptySpot(TrainingPackSpot s) {
    return s.hand.heroCards.trim().isEmpty &&
        s.hand.board.isEmpty &&
        s.hand.actions.values.every((e) => e.isEmpty);
  }

  bool _badTag(String t) {
    final v = t.trim();
    if (v.isEmpty) return true;
    if (v.startsWith('old') || v.startsWith('tmp')) return true;
    if (v.length > 20) return true;
    return false;
  }
}
