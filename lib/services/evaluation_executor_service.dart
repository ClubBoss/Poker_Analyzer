import 'dart:async';
import 'dart:math';

import '../models/action_evaluation_request.dart';
import '../models/evaluation_result.dart';
import '../models/training_spot.dart';
import '../models/saved_hand.dart';
import '../models/summary_result.dart';

/// Handles execution of a single evaluation request.
class EvaluationExecutorService {
  /// Executes the evaluation for [req].
  ///
  /// This stub simulates a delay and introduces a random failure
  /// for debugging purposes.
  Future<void> execute(ActionEvaluationRequest req) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (Random().nextDouble() < 0.2) {
      throw Exception('Simulated evaluation failure');
    }
  }

  /// Evaluates [userAction] taken in [spot] and returns an [EvaluationResult].
  ///
  /// The initial implementation simply checks if the action matches the
  /// expected action for the hero at the given training spot.
  EvaluationResult evaluate(TrainingSpot spot, String userAction) {
    final expectedAction = spot.actions[spot.heroIndex].action;
    final correct = userAction == expectedAction;
    final expectedEquity =
        spot.equities != null && spot.equities!.length > spot.heroIndex
            ? spot.equities![spot.heroIndex].clamp(0.0, 1.0)
            : 0.5;
    final userEquity = correct
        ? expectedEquity
        : (expectedEquity - 0.1).clamp(0.0, 1.0);
    return EvaluationResult(
      correct: correct,
      expectedAction: expectedAction,
      userEquity: userEquity,
      expectedEquity: expectedEquity,
      hint: correct ? null : 'Подумай о диапазоне оппонента',
    );
  }

  /// Generates a summary for a list of saved hands.
  SummaryResult summarizeHands(List<SavedHand> hands) {
    final Map<int, List<SavedHand>> sessions = {};
    for (final hand in hands) {
      sessions.putIfAbsent(hand.sessionId, () => []).add(hand);
    }

    int correct = 0;
    int incorrect = 0;
    final tagErrors = <String, int>{};
    final streets = {
      'Preflop': 0,
      'Flop': 0,
      'Turn': 0,
      'River': 0,
    };
    final positionErrors = <String, int>{};
    final sessionAcc = <int, double>{};

    for (final entry in sessions.entries) {
      int sCorrect = 0;
      int sIncorrect = 0;
      for (final hand in entry.value) {
        final expected = hand.expectedAction;
        final gto = hand.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            sCorrect++;
          } else {
            sIncorrect++;
            final street = hand.boardStreet.clamp(0, 3);
            switch (street) {
              case 0:
                streets['Preflop'] = streets['Preflop']! + 1;
                break;
              case 1:
                streets['Flop'] = streets['Flop']! + 1;
                break;
              case 2:
                streets['Turn'] = streets['Turn']! + 1;
                break;
              default:
                streets['River'] = streets['River']! + 1;
            }
            for (final tag in hand.tags) {
              tagErrors[tag] = (tagErrors[tag] ?? 0) + 1;
            }
            final pos = hand.heroPosition;
            positionErrors[pos] = (positionErrors[pos] ?? 0) + 1;
          }
        }
      }
      final total = sCorrect + sIncorrect;
      if (total > 0) {
        sessionAcc[entry.key] = sCorrect / total * 100;
      }
      correct += sCorrect;
      incorrect += sIncorrect;
    }

    final totalHands = correct + incorrect;
    final accuracy = totalHands > 0 ? correct / totalHands * 100 : 0.0;

    return SummaryResult(
      totalHands: totalHands,
      correct: correct,
      incorrect: incorrect,
      accuracy: accuracy,
      mistakeTagFrequencies: tagErrors,
      streetBreakdown: streets,
      positionMistakeFrequencies: positionErrors,
      accuracyPerSession: sessionAcc,
    );
  }
}
