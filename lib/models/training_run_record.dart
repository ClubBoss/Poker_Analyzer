import 'dart:convert';

class FormatMeta {
  final int spotsPerPack;
  final int streets;
  final double theoryRatio;

  const FormatMeta({
    required this.spotsPerPack,
    required this.streets,
    required this.theoryRatio,
  });

  factory FormatMeta.fromJson(Map<String, dynamic> j) => FormatMeta(
        spotsPerPack: j['spotsPerPack'] as int? ?? 0,
        streets: j['streets'] as int? ?? 1,
        theoryRatio: (j['theoryRatio'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'spotsPerPack': spotsPerPack,
        'streets': streets,
        'theoryRatio': theoryRatio,
      };
}

class TrainingRunRecord {
  final String armId;
  final String packId;
  final double accuracy;
  final double dropoffRate;
  final double timeToComplete;
  final double novelty;
  final double retryRate;
  final String? audience;
  final FormatMeta format;

  TrainingRunRecord({
    required this.armId,
    required this.packId,
    required this.accuracy,
    required this.dropoffRate,
    required this.timeToComplete,
    required this.novelty,
    required this.retryRate,
    this.audience,
    required this.format,
  });

  factory TrainingRunRecord.fromJson(Map<String, dynamic> j) =>
      TrainingRunRecord(
        armId: j['armId'] as String? ?? '',
        packId: j['packId'] as String? ?? '',
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        dropoffRate: (j['dropoffRate'] as num?)?.toDouble() ?? 0,
        timeToComplete: (j['timeToComplete'] as num?)?.toDouble() ?? 0,
        novelty: (j['novelty'] as num?)?.toDouble() ?? 0,
        retryRate: (j['retryRate'] as num?)?.toDouble() ?? 0,
        audience: j['audience'] as String?,
        format: FormatMeta.fromJson(
          j['format'] as Map<String, dynamic>? ?? const {},
        ),
      );

  Map<String, dynamic> toJson() => {
        'armId': armId,
        'packId': packId,
        'accuracy': accuracy,
        'dropoffRate': dropoffRate,
        'timeToComplete': timeToComplete,
        'novelty': novelty,
        'retryRate': retryRate,
        if (audience != null) 'audience': audience,
        'format': format.toJson(),
      };

  @override
  String toString() => jsonEncode(toJson());
}
