import '../models/v2/training_pack_template_v2.dart';
import 'user_profile_preference_service.dart';

class PackRecommendationEngine {
  const PackRecommendationEngine();

  List<TrainingPackTemplateV2> recommend({
    required List<TrainingPackTemplateV2> all,
    Set<String>? preferredTags,
    Set<String>? preferredAudiences,
    Set<int>? preferredDifficulties,
  }) {
    final profile = UserProfilePreferenceService.instance;
    final tagSet = (preferredTags ?? profile.preferredTags)
        .map((e) => e.trim().toLowerCase())
        .toSet();
    final audienceSet = (preferredAudiences ?? profile.preferredAudiences)
        .map((e) => e.trim().toLowerCase())
        .toSet();
    final difficultySet =
        preferredDifficulties ?? profile.preferredDifficulties;

    final entries = <MapEntry<TrainingPackTemplateV2, int>>[];

    for (final tpl in all) {
      var score = 0;

      if (tagSet.isNotEmpty) {
        final tplTags = {for (final t in tpl.tags) t.trim().toLowerCase()};
        for (final tag in tagSet) {
          if (tplTags.contains(tag)) score += 2;
        }
      }

      if (audienceSet.isNotEmpty) {
        final aud = tpl.audience?.trim().toLowerCase();
        if (aud != null && audienceSet.contains(aud)) score += 3;
      }

      if (difficultySet.isNotEmpty) {
        final diff = (tpl.meta['difficulty'] as num?)?.toInt();
        if (diff != null && difficultySet.contains(diff)) score += 1;
      }

      entries.add(MapEntry(tpl, score));
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(10)) e.key];
  }
}
