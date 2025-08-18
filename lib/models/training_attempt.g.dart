// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingAttempt _$TrainingAttemptFromJson(Map<String, dynamic> json) =>
    TrainingAttempt(
      packId: json['packId'] as String,
      spotId: json['spotId'] as String,
      timestamp: TrainingAttempt._dateFromJson(json['timestamp'] as String?),
      accuracy: (json['accuracy'] as num).toDouble(),
      ev: (json['ev'] as num).toDouble(),
      icm: (json['icm'] as num).toDouble(),
    );

Map<String, dynamic> _$TrainingAttemptToJson(TrainingAttempt instance) =>
    <String, dynamic>{
      'packId': instance.packId,
      'spotId': instance.spotId,
      'timestamp': TrainingAttempt._dateToJson(instance.timestamp),
      'accuracy': instance.accuracy,
      'ev': instance.ev,
      'icm': instance.icm,
    };
