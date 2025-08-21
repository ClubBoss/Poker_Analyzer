import '../game_type.dart';
import '../skill_level.dart';
import '../training_pack.dart' show parseGameType;

class LessonStepFilter {
  final int? minXp;
  final Set<String> tags;
  final Set<String> completedLessonIds;
  final GameType? gameType;
  final SkillLevel? skillLevel;

  LessonStepFilter({
    this.minXp,
    Set<String>? tags,
    Set<String>? completedLessonIds,
    this.gameType,
    this.skillLevel,
  })  : tags = tags?.toSet() ?? <String>{},
        completedLessonIds = completedLessonIds?.toSet() ?? <String>{};

  factory LessonStepFilter.fromYaml(Map yaml) {
    final tagsField = yaml['tag'] ?? yaml['tags'];
    final tagSet = <String>{};
    if (tagsField is List) {
      tagSet.addAll(tagsField.map((e) => e.toString()));
    } else if (tagsField is String) {
      tagSet.add(tagsField);
    }
    return LessonStepFilter(
      minXp: (yaml['minXp'] as num?)?.toInt(),
      tags: tagSet,
      completedLessonIds: {
        for (final id in (yaml['completedLessonIds'] as List? ?? []))
          id.toString(),
      },
      gameType:
          yaml['gameType'] != null ? parseGameType(yaml['gameType']) : null,
      skillLevel: yaml['skillLevel'] != null
          ? SkillLevel.values.firstWhere(
              (e) => e.name == yaml['skillLevel'].toString(),
              orElse: () => SkillLevel.beginner,
            )
          : null,
    );
  }

  Map<String, dynamic> toYaml() => {
        if (minXp != null) 'minXp': minXp,
        if (tags.isNotEmpty)
          'tag': tags.length == 1 ? tags.first : tags.toList(),
        if (completedLessonIds.isNotEmpty)
          'completedLessonIds': completedLessonIds.toList(),
        if (gameType != null) 'gameType': gameType!.name,
        if (skillLevel != null) 'skillLevel': skillLevel!.name,
      };
}
