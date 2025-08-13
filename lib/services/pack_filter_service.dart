import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/pack_ux_metadata.dart';

class PackFilterService {
  const PackFilterService();

  List<TrainingPackTemplateV2> filter({
    required List<TrainingPackTemplateV2> templates,
    Set<String>? themes,
    Set<String>? tags,
    Set<TrainingType>? types,
    Set<int>? difficulties,
    Set<String>? audiences,
    TrainingPackLevel? level,
    String? goal,
  }) {
    final themeSet = themes?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final tagSet = tags?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final typeSet = types ?? {};
    final diffSet = difficulties ?? {};
    final audSet = audiences?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final goalStr = goal?.trim().toLowerCase();

    return [
      for (final t in templates)
        if (_matches(
          t,
          themeSet,
          tagSet,
          typeSet,
          diffSet,
          audSet,
          level,
          goalStr,
        ))
          t
    ];
  }

  bool _matches(
    TrainingPackTemplateV2 tpl,
    Set<String> themes,
    Set<String> tags,
    Set<TrainingType> types,
    Set<int> diffs,
    Set<String> audiences,
    TrainingPackLevel? level,
    String? goal,
  ) {
    if (types.isNotEmpty && !types.contains(tpl.trainingType)) return false;

    if (themes.isNotEmpty) {
      final tplThemes = <String>{};
      final raw = tpl.meta['theme'];
      if (raw is String) {
        tplThemes.add(raw.trim().toLowerCase());
      } else if (raw is List) {
        for (final t in raw) {
          tplThemes.add(t.toString().trim().toLowerCase());
        }
      }
      if (tplThemes.intersection(themes).isEmpty) return false;
    }

    if (tags.isNotEmpty) {
      final tplTags = {for (final t in tpl.tags) t.trim().toLowerCase()};
      if (tplTags.intersection(tags).isEmpty) return false;
    }

    if (diffs.isNotEmpty) {
      final level = _difficultyLevel(tpl);
      if (!diffs.contains(level) || level == 0) return false;
    }

    if (audiences.isNotEmpty) {
      final a = (tpl.audience ?? tpl.meta['audience']?.toString() ?? '')
          .trim()
          .toLowerCase();
      if (a.isEmpty || !audiences.contains(a)) return false;
    }

    if (level != null) {
      final lvl = tpl.meta['level']?.toString();
      if (lvl != level.name) return false;
    }

    if (goal != null && goal.isNotEmpty) {
      final g =
          (tpl.goal.isNotEmpty ? tpl.goal : tpl.meta['goal']?.toString() ?? '')
              .trim()
              .toLowerCase();
      if (g != goal) return false;
    }
    return true;
  }

  int _difficultyLevel(TrainingPackTemplateV2 tpl) {
    final diff = (tpl.meta['difficulty'] as num?)?.toInt();
    if (diff == 1) return 1;
    if (diff == 2) return 2;
    if (diff != null && diff >= 3) return 3;
    return 0;
  }
}
