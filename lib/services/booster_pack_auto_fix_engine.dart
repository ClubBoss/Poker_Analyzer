import '../models/theory_pack_model.dart';
import 'theory_pack_auto_fix_engine.dart';

/// Performs cleanup and auto-fixes on booster theory packs.
class BoosterPackAutoFixEngine extends TheoryPackAutoFixEngine {
  BoosterPackAutoFixEngine();

  @override
  TheoryPackModel autoFix(TheoryPackModel pack) {
    final fixed = super.autoFix(pack);

    String clean(String v) => v.replaceAll(RegExp(r'\s+'), ' ').trim();

    final sections = <TheorySectionModel>[];
    for (final s in fixed.sections) {
      final type = clean(s.type).toLowerCase();
      if (type == 'info') continue; // info sections are not allowed in boosters
      sections.add(
        TheorySectionModel(
          title: clean(s.title),
          text: clean(s.text),
          type: type,
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        TheorySectionModel(
          title: 'Placeholder',
          text: 'Content will be added later',
          type: 'tip',
        ),
      );
    }

    return TheoryPackModel(
      id: fixed.id,
      title: fixed.title,
      sections: sections,
    );
  }
}
