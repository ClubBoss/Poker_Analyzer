part of 'drill_result.dart';

DrillResult _$DrillResultFromJson(Map<String, dynamic> json) => DrillResult(
  templateId: json['templateId'] as String,
  templateName: json['templateName'] as String,
  date: DrillResult._dateFromJson(json['date'] as String?),
  total: (json['total'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  evLoss: (json['evLoss'] as num).toDouble(),
  wrongSpotIds:
      (json['wrongSpotIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$DrillResultToJson(DrillResult instance) =>
    <String, dynamic>{
      'templateId': instance.templateId,
      'templateName': instance.templateName,
      'date': DrillResult._dateToJson(instance.date),
      'total': instance.total,
      'correct': instance.correct,
      'evLoss': instance.evLoss,
      'wrongSpotIds': instance.wrongSpotIds,
    };
