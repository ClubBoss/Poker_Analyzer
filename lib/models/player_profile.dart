import 'game_type.dart';
import 'skill_level.dart';

class PlayerProfile {
  int xp;
  Set<String> tags;
  GameType gameType;
  SkillLevel skillLevel;
  Set<String> completedLessonIds;
  Map<String, double> tagAccuracy;

  PlayerProfile({
    this.xp = 0,
    Set<String>? tags,
    this.gameType = GameType.tournament,
    this.skillLevel = SkillLevel.beginner,
    Set<String>? completedLessonIds,
    Map<String, double>? tagAccuracy,
  })  : tags = tags ?? <String>{},
        completedLessonIds = completedLessonIds ?? <String>{},
        tagAccuracy = tagAccuracy ?? <String, double>{};
}
