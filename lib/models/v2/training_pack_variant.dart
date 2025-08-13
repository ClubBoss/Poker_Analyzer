import 'hero_position.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;

class TrainingPackVariant {
  final HeroPosition position;
  final GameType gameType;
  final String? tag;
  final String? rangeId;

  const TrainingPackVariant({
    required this.position,
    required this.gameType,
    this.tag,
    this.rangeId,
  });

  factory TrainingPackVariant.fromJson(Map<String, dynamic> j) =>
      TrainingPackVariant(
        position: HeroPosition.values.firstWhere(
          (e) => e.name == j['position'],
          orElse: () => HeroPosition.unknown,
        ),
        gameType: parseGameType(j['gameType']),
        tag: j['tag'] as String?,
        rangeId: j['rangeId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'position': position.name,
        'gameType': gameType.name,
        if (tag != null) 'tag': tag,
        if (rangeId != null) 'rangeId': rangeId,
      };
}
