import 'package:json_annotation/json_annotation.dart';

part 'card_model.g.dart';

@JsonSerializable()
class CardModel {
  final String rank; // Пример: 'A', 'K', '9'
  final String suit; // Пример: '♠', '♥', '♦', '♣'

  CardModel({required this.rank, required this.suit});

  @override
  String toString() {
    return '$rank$suit';
  }

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);
  Map<String, dynamic> toJson() => _$CardModelToJson(this);
}
