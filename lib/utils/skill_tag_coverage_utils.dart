import '../models/skill_tag_stats.dart';

/// Summary statistics for a single category.
class CategorySummary {
  final int total;
  final int covered;
  final int uncovered;
  final double avg;

  const CategorySummary(
    this.total,
    this.covered,
    this.uncovered,
    this.avg,
  );
}

/// Computes coverage summary per category given the global stats.
Map<String, CategorySummary> computeCategorySummary(
  SkillTagStats stats,
  Set<String> allTags,
  Map<String, String> tagCategoryMap,
) {
  final totals = <String, int>{};
  final covered = <String, Set<String>>{};
  for (final tag in allTags) {
    final norm = tag.toLowerCase();
    final cat = tagCategoryMap[norm] ?? 'uncategorized';
    totals[cat] = (totals[cat] ?? 0) + 1;
    if ((stats.tagCounts[norm] ?? 0) > 0) {
      (covered[cat] ??= <String>{}).add(norm);
    }
  }

  final result = <String, CategorySummary>{};
  totals.forEach((cat, total) {
    final coveredCount = covered[cat]?.length ?? 0;
    final uncovered = total - coveredCount;
    final avg = total == 0 ? 0 : coveredCount / total * 100;
    result[cat] = CategorySummary(total, coveredCount, uncovered, avg);
  });
  return result;
}

