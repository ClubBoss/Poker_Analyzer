import '../models/evaluation_result.dart';
import '../models/v2/training_pack_spot.dart';

class EvaluationLogicService {
  static EvaluationResult evaluateDecision(
    TrainingPackSpot spot, {
    double evThreshold = -0.01,
    bool useIcm = false,
  }) {
    final value = useIcm ? spot.heroIcmEv : spot.heroEv;
    final correct = value != null && value >= evThreshold;
    final reason = value == null
        ? 'No EV data'
        : '${value.toStringAsFixed(2)} EV ${value >= evThreshold ? 'above' : 'below'} threshold';
    return EvaluationResult(
      correct: correct,
      expectedAction: '',
      userEquity: 0,
      expectedEquity: 0,
      ev: value,
      hint: reason,
    );
  }
}
