import 'package:json_annotation/json_annotation.dart';

part 'reward_analytics_entry.g.dart';

@JsonSerializable()
class RewardAnalyticsEntry {
  final String tag;
  final String rewardType;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime timestamp;

  const RewardAnalyticsEntry({
    required this.tag,
    required this.rewardType,
    required this.timestamp,
  });

  factory RewardAnalyticsEntry.fromJson(Map<String, dynamic> json) =>
      _$RewardAnalyticsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$RewardAnalyticsEntryToJson(this);

  static DateTime _dateFromJson(String? date) =>
      DateTime.tryParse(date ?? '') ?? DateTime.now();
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
