import 'hero_position.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import 'package:json_annotation/json_annotation.dart';

part 'training_pack_variant.g.dart';

@JsonSerializable()
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
      _$TrainingPackVariantFromJson(j);
  Map<String, dynamic> toJson() => _$TrainingPackVariantToJson(this);
}
