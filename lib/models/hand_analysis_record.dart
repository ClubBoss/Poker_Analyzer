import 'package:json_annotation/json_annotation.dart';

import 'card_model.dart';

part 'hand_analysis_record.g.dart';

@JsonSerializable()
class HandAnalysisRecord {
  final String card1;
  final String card2;
  final int stack;
  final int playerCount;
  final int heroIndex;
  final double ev;
  final double icm;
  final String action;
  final String hint;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime date;

  HandAnalysisRecord({
    required this.card1,
    required this.card2,
    required this.stack,
    required this.playerCount,
    required this.heroIndex,
    required this.ev,
    required this.icm,
    required this.action,
    required this.hint,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  List<CardModel> get cards => [
        CardModel(rank: card1[0], suit: card1.substring(1)),
        CardModel(rank: card2[0], suit: card2.substring(1)),
      ];

  factory HandAnalysisRecord.fromJson(Map<String, dynamic> json) =>
      _$HandAnalysisRecordFromJson(json);

  Map<String, dynamic> toJson() => _$HandAnalysisRecordToJson(this);

  static DateTime _dateFromJson(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime.now();
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
