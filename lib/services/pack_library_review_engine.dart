import '../models/yaml_pack_review_report.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackLibraryReviewEngine {
  PackLibraryReviewEngine();

  YamlPackReviewReport review(TrainingPackTemplateV2 pack) {
    final warnings = <String>[];
    final suggestions = <String>[];
    final goal = pack.goal.trim();
    if (goal.isEmpty || goal.length < 8) {
      warnings.add('goal_short');
      suggestions.add('Add clear goal');
    }
    final tags = pack.tags;
    if (tags.isEmpty) {
      warnings.add('missing_tags');
      suggestions.add('Add tags');
    } else {
      final seen = <String>{};
      for (final t in tags) {
        final v = t.trim();
        if (v.isEmpty || _badTag(v)) warnings.add('bad_tag:$t');
        if (!seen.add(v.toLowerCase())) warnings.add('duplicate_tag:$t');
      }
    }
    final total =
        (pack.meta['totalWeight'] as num?)?.toDouble() ??
        pack.spotCount.toDouble();
    if (total > 0) {
      final ev = (pack.meta['evCovered'] as num?)?.toDouble() ?? 0;
      final icm = (pack.meta['icmCovered'] as num?)?.toDouble() ?? 0;
      final pct = (ev + icm) / (2 * total);
      if (pct < 0.5) {
        warnings.add('low_coverage:${(pct * 100).round()}');
        suggestions.add('Increase evaluation coverage');
      }
    }
    final evScore = (pack.meta['evScore'] as num?)?.toDouble();
    final icmScore = (pack.meta['icmScore'] as num?)?.toDouble();
    if (evScore != null && (evScore < 0 || evScore > 100))
      warnings.add('bad_evScore:$evScore');
    if (icmScore != null && (icmScore < 0 || icmScore > 100))
      warnings.add('bad_icmScore:$icmScore');
    if (pack.positions.isEmpty) suggestions.add('Specify positions');
    if (pack.audience == null || pack.audience!.trim().isEmpty)
      suggestions.add('Specify audience');
    if (pack.category == null || pack.category!.trim().isEmpty)
      suggestions.add('Specify category');
    return YamlPackReviewReport(warnings: warnings, suggestions: suggestions);
  }

  bool _badTag(String t) {
    final v = t.trim();
    if (v.isEmpty) return true;
    if (v.startsWith('old') || v.startsWith('tmp')) return true;
    if (v.length > 20) return true;
    return false;
  }
}
