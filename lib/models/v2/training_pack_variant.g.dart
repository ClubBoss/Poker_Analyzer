// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_pack_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingPackVariant _$TrainingPackVariantFromJson(Map<String, dynamic> json) =>
    TrainingPackVariant(
      position: $enumDecode(_$HeroPositionEnumMap, json['position']),
      gameType: $enumDecode(_$GameTypeEnumMap, json['gameType']),
      tag: json['tag'] as String?,
      rangeId: json['rangeId'] as String?,
    );

Map<String, dynamic> _$TrainingPackVariantToJson(
        TrainingPackVariant instance) =>
    <String, dynamic>{
      'position': _$HeroPositionEnumMap[instance.position]!,
      'gameType': _$GameTypeEnumMap[instance.gameType]!,
      'tag': instance.tag,
      'rangeId': instance.rangeId,
    };

const _$HeroPositionEnumMap = {
  HeroPosition.sb: 'sb',
  HeroPosition.bb: 'bb',
  HeroPosition.utg: 'utg',
  HeroPosition.mp: 'mp',
  HeroPosition.co: 'co',
  HeroPosition.btn: 'btn',
  HeroPosition.unknown: 'unknown',
};

const _$GameTypeEnumMap = {
  GameType.tournament: 'tournament',
  GameType.cash: 'cash',
};
