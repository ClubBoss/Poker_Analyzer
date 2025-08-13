import 'package:uuid/uuid.dart';
import '../models/saved_hand.dart';
import '../models/summary_result.dart';
import '../models/eval_request.dart';
import '../models/training_spot.dart';
import '../helpers/hand_utils.dart';
import 'evaluation_executor_service.dart';

class SessionAnalysisResult {
  final List<SavedHand> hands;
  final SummaryResult summary;
  const SessionAnalysisResult({required this.hands, required this.summary});
}

class SessionAnalysisService {
  final EvaluationExecutorService _exec;
  const SessionAnalysisService(this._exec);

  Future<SessionAnalysisResult> analyze(List<SavedHand> hands) async {
    final evaluated = <SavedHand>[];
    for (final h in hands) {
      final act = heroAction(h);
      if (act == null) continue;
      final spot = TrainingSpot.fromSavedHand(h);
      final req =
          EvalRequest(hash: const Uuid().v4(), spot: spot, action: act.action);
      final res = await _exec.evaluate(req);
      String? gto;
      if (!res.isError &&
          res.reason != null &&
          res.reason!.startsWith('Expected ')) {
        gto = res.reason!.substring(9);
      } else if (!res.isError && res.reason == null) {
        gto = act.action;
      }
      evaluated.add(h.copyWith(expectedAction: act.action, gtoAction: gto));
    }
    final summary = _exec.summarizeHands(evaluated);
    return SessionAnalysisResult(hands: evaluated, summary: summary);
  }
}
