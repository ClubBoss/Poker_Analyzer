import '../models/skill_tag_stats.dart';
import '../models/v2/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';

/// Generates additional spot templates targeting underrepresented skill tags.
class TagBalancerEngine {
  /// Maximum number of boost templates returned by [balance].
  final int maxBoostCount;

  const TagBalancerEngine({this.maxBoostCount = 5});

  /// Returns additional templates from [baseSet] that help balance [coverage].
  ///
  /// Tags whose frequency falls below the median in [coverage] are considered
  /// underrepresented. Spots from [baseSet.template.spots] containing these
  /// tags are selected until [maxBoostCount] templates are returned. Each tag is
  /// boosted at most once.
  List<TrainingPackSpot> balance(
    TrainingPackTemplateSet baseSet,
    SkillTagStats coverage,
  ) {
    if (baseSet.template.spots.isEmpty) return [];
    if (coverage.tagCounts.isEmpty) return [];

    final values = coverage.tagCounts.values.toList()..sort();
    final median = values[values.length ~/ 2];
    final weakTags = coverage.tagCounts.entries
        .where((e) => e.value < median)
        .map((e) => e.key)
        .toSet();
    if (weakTags.isEmpty) return [];

    final result = <TrainingPackSpot>[];
    final usedTags = <String>{};

    for (final spot in baseSet.template.spots) {
      if (result.length >= maxBoostCount) break;
      final match = spot.tags.firstWhere(
        (t) => weakTags.contains(t) && !usedTags.contains(t),
        orElse: () => '',
      );
      if (match.isEmpty) continue;
      result.add(
        TrainingPackSpot.fromJson(Map<String, dynamic>.from(spot.toJson())),
      );
      usedTags.add(match);
    }
    return result;
  }
}
