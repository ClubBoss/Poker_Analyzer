import '../game_type.dart';
import '../skill_level.dart';
import '../training_pack.dart' show parseGameType;

class TrackUnlockCondition {
  final int? minXp;
  final Set<String> requiredTags;
  final Set<String> completedLessonIds;
  final GameType? gameType;
  final SkillLevel? skillLevel;

  TrackUnlockCondition({
    this.minXp,
    Set<String>? requiredTags,
    Set<String>? completedLessonIds,
    this.gameType,
    this.skillLevel,
  })  : requiredTags = requiredTags?.toSet() ?? <String>{},
        completedLessonIds = completedLessonIds?.toSet() ?? <String>{};

  factory TrackUnlockCondition.fromYaml(Map yaml) {
    final tagsField = yaml['requiredTags'];
    final tagSet = <String>{};
    if (tagsField is List) {
      tagSet.addAll(tagsField.map((e) => e.toString()));
    } else if (tagsField is String) {
      tagSet.add(tagsField);
    }
    return TrackUnlockCondition(
      minXp: (yaml['minXp'] as num?)?.toInt(),
      requiredTags: tagSet,
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
        if (requiredTags.isNotEmpty)
          'requiredTags': requiredTags.length == 1
              ? requiredTags.first
              : requiredTags.toList(),
        if (completedLessonIds.isNotEmpty)
          'completedLessonIds': completedLessonIds.toList(),
        if (gameType != null) 'gameType': gameType!.name,
        if (skillLevel != null) 'skillLevel': skillLevel!.name,
      };
}
