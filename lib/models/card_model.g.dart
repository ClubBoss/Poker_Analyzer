part of 'card_model.dart';

CardModel _$CardModelFromJson(Map<String, dynamic> json) =>
    CardModel(rank: json['rank'] as String, suit: json['suit'] as String);

Map<String, dynamic> _$CardModelToJson(CardModel instance) => <String, dynamic>{
      'rank': instance.rank,
      'suit': instance.suit,
    };
