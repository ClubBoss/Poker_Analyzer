import 'training_spot.dart';

class EvalRequest {
  final String hash;
  final TrainingSpot spot;
  final String action;

  EvalRequest({required this.hash, required this.spot, required this.action});
}
