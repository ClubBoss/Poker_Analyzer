import "v2/training_pack_spot.dart";

class TrainingSpotAttempt {
  final TrainingPackSpot spot;
  final String userAction;
  final String correctAction;
  final double evDiff;

  TrainingSpotAttempt({
    required this.spot,
    required this.userAction,
    required this.correctAction,
    required this.evDiff,
  });

  Map<String, dynamic> toJson() => {
        'spot': spot.toJson(),
        'userAction': userAction,
        'correctAction': correctAction,
        'evDiff': evDiff,
      };

  factory TrainingSpotAttempt.fromJson(Map<String, dynamic> json) =>
      TrainingSpotAttempt(
        spot: TrainingPackSpot.fromJson(
            Map<String, dynamic>.from(json['spot'] as Map)),
        userAction: json['userAction'] as String? ?? '',
        correctAction: json['correctAction'] as String? ?? '',
        evDiff: (json['evDiff'] as num?)?.toDouble() ?? 0.0,
      );
}
