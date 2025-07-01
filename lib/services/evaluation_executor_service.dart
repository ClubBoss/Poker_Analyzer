import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/action_evaluation_request.dart';
import '../models/evaluation_result.dart';
import '../models/eval_request.dart';
import '../models/eval_result.dart';
import '../models/training_spot.dart';
import '../models/saved_hand.dart';
import '../models/summary_result.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/mistake_severity.dart';
import 'goals_service.dart';
import 'training_stats_service.dart';

/// Interface for evaluation execution logic.
abstract class EvaluationExecutor {
  Future<void> execute(ActionEvaluationRequest req);
  EvaluationResult evaluateSpot(BuildContext context, TrainingSpot spot, String userAction);
  Future<EvalResult> evaluate(EvalRequest request);
  SummaryResult summarizeHands(List<SavedHand> hands);
}

/// Handles execution of a single evaluation request.
class EvaluationExecutorService implements EvaluationExecutor {
  EvaluationExecutorService._internal() {
    _initFuture;
  }
  static final EvaluationExecutorService _instance =
      EvaluationExecutorService._internal();

  factory EvaluationExecutorService() => _instance;

  final Queue<_QueueItem> _queue = Queue();
  final Map<String, EvalResult> _cache = {};
  bool _processing = false;

  static const _evaluatedKey = 'eval_total_evaluated';
  static const _correctKey = 'eval_total_correct';
  int _totalEvaluated = 0;
  int _totalCorrect = 0;
  late final Future<void> _initFuture = _loadStats();

  int get totalEvaluated => _totalEvaluated;
  int get totalCorrect => _totalCorrect;
  double get accuracy =>
      _totalEvaluated == 0 ? 0 : _totalCorrect / _totalEvaluated;

  Future<void> resetAccuracy() async {
    _totalEvaluated = 0;
    _totalCorrect = 0;
    await _saveStats();
  }

  @override
  Future<EvalResult> evaluate(EvalRequest request) async {
    await _initFuture;
    final cached = _cache[request.hash];
    if (cached != null) {
      TrainingStatsService.instance?.addEvalResult(cached.score);
      return Future.value(cached);
    }
    final completer = Completer<EvalResult>();
    _queue.add(_QueueItem(request, completer));
    _processQueue();
    return completer.future
        .timeout(const Duration(seconds: 3))
        .then((res) {
      TrainingStatsService.instance?.addEvalResult(res.score);
      return res;
    });
  }

  void _processQueue() {
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    final item = _queue.removeFirst();
    _evaluate(item.request).then((res) {
      _cache[item.request.hash] = res;
      item.completer.complete(res);
      if (!res.isError) {
        _totalEvaluated += 1;
        if (res.score == 1) _totalCorrect += 1;
        unawaited(_saveStats());
      }
    }).catchError((e) {
      item.completer
          .complete(EvalResult(isError: true, reason: '$e', score: 0));
    }).whenComplete(() {
      _processing = false;
      _processQueue();
    });
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _totalEvaluated = prefs.getInt(_evaluatedKey) ?? 0;
    _totalCorrect = prefs.getInt(_correctKey) ?? 0;
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_evaluatedKey, _totalEvaluated);
    await prefs.setInt(_correctKey, _totalCorrect);
  }

  Future<EvalResult> _evaluate(EvalRequest request) async {
    final spot = request.spot;
    final expectedAction =
        spot.recommendedAction ?? _evaluatePushFold(spot) ?? _heroAction(spot) ?? '-';
    final normExpected = expectedAction.trim().toLowerCase();
    final normUser = request.action.trim().toLowerCase();
    final correct = normUser == normExpected;
    final reason = correct ? null : 'Expected $expectedAction';
    final score = correct ? 1.0 : 0.0;
    return EvalResult(isError: false, reason: reason, score: score);
  }

  /// Executes the evaluation for [req]. Stores the result in
  /// `req.metadata['result']` if spot data is provided.
  @override
  Future<void> execute(ActionEvaluationRequest req) async {
    final map = req.metadata?['spot'] as Map<String, dynamic>?;
    final action = req.metadata?['userAction'] as String?;
    if (map == null || action == null) {
      throw Exception('Missing evaluation data');
    }
    final spot = TrainingSpot.fromJson(map);
    final ctx = WidgetsBinding.instance.renderViewElement;
    if (ctx == null) throw Exception('No context');
    final result = evaluateSpot(ctx, spot, action);
    req.metadata?['result'] = result.toJson();
  }

  /// Evaluates [userAction] taken in [spot] and returns an [EvaluationResult].
  ///
  /// The initial implementation simply checks if the action matches the
  /// expected action for the hero at the given training spot.
  @override
  EvaluationResult evaluateSpot(BuildContext context, TrainingSpot spot, String userAction) {
    final expectedAction =
        spot.recommendedAction ?? _evaluatePushFold(spot) ?? _heroAction(spot) ?? '-';
    final normExpected = expectedAction.trim().toLowerCase();
    final normUser = userAction.trim().toLowerCase();
    final correct = normUser == normExpected;
    final expectedEquity =
        spot.equities != null && spot.equities!.length > spot.heroIndex
            ? spot.equities![spot.heroIndex].clamp(0.0, 1.0)
            : 0.5;
    final userEquity = correct
        ? expectedEquity
        : (expectedEquity - 0.1).clamp(0.0, 1.0);
    final result = EvaluationResult(
      correct: correct,
      expectedAction: expectedAction,
      userEquity: userEquity,
      expectedEquity: expectedEquity,
      hint: correct ? null : 'Пересмотри диапазон пуша',
    );

    final goals = GoalsService.instance;
    if (goals != null) {
      if (correct) {
        final progress = goals.goals.length > 1 ? goals.goals[1].progress + 1 : 1;
        goals.setProgress(1, progress, context: context);
        goals.updateErrorFreeStreak(true, context: context);
      } else {
        goals.setProgress(1, 0, context: context);
        goals.updateErrorFreeStreak(false, context: context);
      }
    }

    return result;
  }

  String? _heroAction(TrainingSpot spot) {
    for (final a in spot.actions) {
      if (a.playerIndex == spot.heroIndex) return a.action;
    }
    return null;
  }

  String? _evaluatePushFold(TrainingSpot spot) {
    if (spot.boardCards.isNotEmpty) return null;
    if (spot.playerCards.length <= spot.heroIndex) return null;
    final cards = spot.playerCards[spot.heroIndex];
    if (cards.length < 2) return null;
    final stack = spot.stacks.isNotEmpty ? spot.stacks[spot.heroIndex] : 0;
    if (stack > 15) return null;
    final r1 = _rankValue(cards[0].rank);
    final r2 = _rankValue(cards[1].rank);
    final pair = cards[0].rank == cards[1].rank;
    final suited = cards[0].suit == cards[1].suit;
    final high = r1 > r2 ? r1 : r2;
    final low = r1 > r2 ? r2 : r1;
    if (stack <= 15) {
      if (pair || high >= 14) return 'push';
      if (high == 13 && low >= 9) return 'push';
      if (high >= 11 && low >= 10 && suited) return 'push';
    }
    return 'fold';
  }

  int _rankValue(String r) {
    const map = {
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      'T': 10,
      'J': 11,
      'Q': 12,
      'K': 13,
      'A': 14,
    };
    return map[r] ?? 0;
  }

  /// Generates a summary for a list of saved hands.
  @override
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

  Future<EvaluationResult> evaluate(TrainingPackSpot spot) async {
    final ctx = WidgetsBinding.instance.renderViewElement;
    if (ctx == null) throw Exception('No context');
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[]
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1))
    ];
    final actions = <ActionEntry>[];
    for (final list in hand.actions.values) {
      for (final a in list) {
        actions.add(ActionEntry(a.street, a.playerIndex, a.action,
            amount: a.amount,
            generated: a.generated,
            manualEvaluation: a.manualEvaluation,
            customLabel: a.customLabel));
      }
    }
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++)
        hand.stacks['$i']?.round() ?? 0
    ];
    final positions = List.generate(hand.playerCount, (_) => '');
    if (hand.heroIndex < positions.length) {
      positions[hand.heroIndex] = hand.position.label;
    }
    final spotData = TrainingSpot(
      playerCards: playerCards,
      boardCards: boardCards,
      actions: actions,
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.playerCount,
      playerTypes: List.generate(hand.playerCount, (_) => PlayerType.unknown),
      positions: positions,
      stacks: stacks,
      createdAt: DateTime.now(),
    );
    ActionEntry? heroAct;
    for (final a in actions) {
      if (a.playerIndex == hand.heroIndex) {
        heroAct = a;
        break;
      }
    }
    final action = heroAct?.action ?? '-';
    return evaluateSpot(ctx, spotData, action);
  }

  /// Classifies [mistakeCount] into a [MistakeSeverity] level.
  MistakeSeverity classifySeverity(int mistakeCount) {
    if (mistakeCount >= 10) return MistakeSeverity.high;
    if (mistakeCount >= 4) return MistakeSeverity.medium;
    return MistakeSeverity.low;
  }
}

class _QueueItem {
  final EvalRequest request;
  final Completer<EvalResult> completer;
  _QueueItem(this.request, this.completer);
}
