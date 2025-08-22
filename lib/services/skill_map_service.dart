import 'tag_mastery_service.dart';

class SkillMapService {
  final TagMasteryService mastery;
  SkillMapService({required this.mastery});

  Future<List<String>> getWeakestTags([int count = 2]) async {
    return mastery.topWeakTags(count);
  }
}
