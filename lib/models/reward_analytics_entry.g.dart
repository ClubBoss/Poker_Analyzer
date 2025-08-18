// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_analytics_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardAnalyticsEntry _$RewardAnalyticsEntryFromJson(
        Map<String, dynamic> json) =>
    RewardAnalyticsEntry(
      tag: json['tag'] as String,
      rewardType: json['rewardType'] as String,
      timestamp:
          RewardAnalyticsEntry._dateFromJson(json['timestamp'] as String?),
    );

Map<String, dynamic> _$RewardAnalyticsEntryToJson(
        RewardAnalyticsEntry instance) =>
    <String, dynamic>{
      'tag': instance.tag,
      'rewardType': instance.rewardType,
      'timestamp': RewardAnalyticsEntry._dateToJson(instance.timestamp),
    };
