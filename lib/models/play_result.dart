import 'v2/training_pack_spot.dart';

class PlayResult {
  final String spotId;
  final bool isCorrect;
  final double? evGain;
  final TrainingPackSpot spot;

  const PlayResult({
    required this.spotId,
    required this.spot,
    required this.isCorrect,
    this.evGain,
  });

  Map<String, dynamic> toJson() => {
    'spotId': spotId,
    'isCorrect': isCorrect,
    if (evGain != null) 'evGain': evGain,
    'spot': spot.toJson(),
  };

  factory PlayResult.fromJson(Map<String, dynamic> json) => PlayResult(
    spotId: json['spotId'] as String? ?? '',
    spot: TrainingPackSpot.fromJson(
      Map<String, dynamic>.from(json['spot'] as Map),
    ),
    isCorrect: json['isCorrect'] as bool? ?? false,
    evGain: (json['evGain'] as num?)?.toDouble(),
  );
}
