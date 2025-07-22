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
}
