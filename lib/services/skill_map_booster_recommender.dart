import 'tag_mastery_service.dart';

class SkillMapBoosterRecommender {
  Future<List<String>> getWeakTags({
    required TagMasteryService mastery,
    int maxTags = 3,
    double threshold = 0.6,
  }) async {
    final map = await mastery.computeMastery();
    final list = [
      for (final e in map.entries)
        if (e.value < threshold) MapEntry(e.key, e.value),
    ]..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in list.take(maxTags)) e.key];
  }
}
