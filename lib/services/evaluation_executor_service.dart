import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

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
import '../helpers/hand_utils.dart';
import '../helpers/mistake_advice.dart';
import 'mistake_categorizer.dart';
import 'saved_hand_manager_service.dart';
import 'push_fold_ev_service.dart';
import 'goals_service.dart';
import 'mistake_hint_service.dart';
import '../helpers/push_fold_helper.dart';
import 'training_stats_service.dart';
import '../models/v2/training_pack_template.dart';
import 'remote_ev_service.dart';
import 'icm_push_ev_service.dart';
import '../utils/template_coverage_utils.dart';
import '../helpers/training_pack_storage.dart';
import '../services/evaluation_logic_service.dart';
import 'evaluation_settings_service.dart';
import '../models/evaluation_mode.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

/// Interface for evaluation execution logic.
abstract class EvaluationExecutor {
  Future<void> execute(ActionEvaluationRequest req);
  EvaluationResult evaluateSpot(
      BuildContext context, TrainingSpot spot, String userAction);
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
    return completer.future.timeout(const Duration(seconds: 3)).then((res) {
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
    String? expectedAction;
    if (spot.recommendedAction != null) {
      expectedAction = spot.recommendedAction;
    } else {
      final cards = spot.playerCards.length > spot.heroIndex
          ? spot.playerCards[spot.heroIndex]
          : <CardModel>[];
      if (spot.boardCards.isEmpty && cards.length >= 2) {
        final code = handCode(
            '${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}');
        final stack = spot.stacks.isNotEmpty ? spot.stacks[spot.heroIndex] : 0;
        if (code != null && stack <= 15) {
          final ev = computePushEV(
            heroBbStack: stack,
            bbCount: spot.numberOfPlayers - 1,
            heroHand: code,
            anteBb: spot.anteBb,
          );
          expectedAction = ev >= 0 ? 'push' : 'fold';
        }
      }
      expectedAction ??= _heroAction(spot) ?? '-';
    }
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
  EvaluationResult evaluateSpot(
      BuildContext context, TrainingSpot spot, String userAction) {
    final expectedAction = spot.recommendedAction ??
        _evaluatePushFold(spot) ??
        _heroAction(spot) ??
        '-';
    final normExpected = expectedAction.trim().toLowerCase();
    final normUser = userAction.trim().toLowerCase();
    final correct = normUser == normExpected;
    final expectedEquity =
        spot.equities != null && spot.equities!.length > spot.heroIndex
            ? spot.equities![spot.heroIndex].clamp(0.0, 1.0)
            : 0.5;
    final userEquity =
        correct ? expectedEquity : (expectedEquity - 0.1).clamp(0.0, 1.0);
    String? hint;
    if (!correct) {
      for (final t in spot.tags) {
        final adv = kMistakeAdvice[t];
        if (adv != null && !MistakeHintService.instance.isShown(t)) {
          hint = adv;
          unawaited(MistakeHintService.instance.markShown(t));
          break;
        }
      }
      hint ??= 'Пересмотри диапазон пуша';
    }
    final result = EvaluationResult(
      correct: correct,
      expectedAction: expectedAction,
      userEquity: userEquity,
      expectedEquity: expectedEquity,
      hint: hint,
    );

    final goals = GoalsService.instance;
    if (goals != null) {
      if (correct) {
        final progress =
            goals.goals.length > 1 ? goals.goals[1].progress + 1 : 1;
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
    final code = handCode(
        '${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}');
    if (code == null) return null;
    final threshold = kPushFoldThresholds[code];
    if (threshold != null && stack <= threshold) return 'push';
    return 'fold';
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
      for (var i = 0; i < hand.playerCount; i++) hand.stacks['$i']?.round() ?? 0
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

  Future<void> evaluateSingle(
    BuildContext context,
    TrainingPackSpot spot, {
    TrainingPackTemplate? template,
    int anteBb = 0,
    EvaluationMode mode = EvaluationMode.ev,
    SavedHand? hand,
  }) async {
    String? category;
    final prevEv = spot.heroEv;
    final prevIcm = spot.heroIcmEv;
    final settings = EvaluationSettingsService.instance;
    if (!settings.offline) {
      try {
        await const RemoteEvService().evaluateIcm(spot, anteBb: anteBb);
      } catch (_) {}
    } else {
      final hero = spot.hand.heroIndex;
      final code = handCode(spot.hand.heroCards);
      if (code != null) {
        final stacks = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            spot.hand.stacks['$i']?.round() ?? 0
        ];
        final ev = computePushEV(
          heroBbStack: stacks[hero],
          bbCount: stacks.length - 1,
          heroHand: code,
          anteBb: anteBb,
        );
        final icm = computeLocalIcmPushEV(
          chipStacksBb: stacks,
          heroIndex: hero,
          heroHand: code,
          anteBb: anteBb,
        );
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            a.ev = ev;
            a.icmEv = icm;
            break;
          }
        }
      }
    }
    if (spot.heroEv == null) {
      await const PushFoldEvService().evaluate(spot, anteBb: anteBb);
    }
    if (spot.heroIcmEv == null) {
      await const PushFoldEvService().evaluateIcm(spot, anteBb: anteBb);
    }
    if ((prevEv == null && spot.heroEv != null) ||
        (prevIcm == null && spot.heroIcmEv != null)) {
      spot.dirty = true;
    }
    final prev = spot.evalResult;
    final prevAction = spot.correctAction;
    final prevExpl = spot.explanation;
    spot.evalResult = EvaluationLogicService.evaluateDecision(
      spot,
      evThreshold: settings.evThreshold,
      useIcm: settings.useIcm,
    );
    final hadTag = spot.tags.contains('Mistake');
    if (spot.evalResult != null && !spot.evalResult!.correct && !hadTag) {
      spot.tags.add('Mistake');
    } else if (spot.evalResult != null && spot.evalResult!.correct && hadTag) {
      spot.tags.remove('Mistake');
    }
    final heroPushEv = spot.heroEv ?? 0;
    const foldEv = 0.0;
    spot.correctAction = heroPushEv >= foldEv ? 'push' : 'fold';
    spot.explanation = spot.correctAction == 'push'
        ? '+${(heroPushEv - foldEv).toStringAsFixed(2)} BB vs fold'
        : '${(foldEv - heroPushEv).toStringAsFixed(2)} BB better to fold';
    if (hand != null) {
      final act = heroAction(hand)?.action.trim().toLowerCase();
      if (act != null) {
        final bestEv = spot.correctAction == 'push' ? heroPushEv : foldEv;
        final heroEv = act == 'push' ? heroPushEv : foldEv;
        double loss = bestEv - heroEv;
        var updated = hand.copyWith(
          gtoAction: spot.correctAction,
          evLoss: loss,
        );
        if (updated.category == null || updated.category!.isEmpty) {
          final cat = const MistakeCategorizer().classify(updated);
          updated = updated.copyWith(category: cat);
        }
        await context.read<SavedHandManagerService>().save(updated);
        category = updated.category;
      }
    }
    if (template != null) {
      TemplateCoverageUtils.recountAll(template);
      final changed = prev == null ||
          !const DeepCollectionEquality().equals(
            prev.toJson(),
            spot.evalResult!.toJson(),
          );
      final tagChanged = hadTag != spot.tags.contains('Mistake');
      final autoChanged =
          prevAction != spot.correctAction || prevExpl != spot.explanation;
      if (changed || tagChanged || autoChanged) {
        await TrainingPackStorage.save([template]);
      }
    }
    if (spot.evalResult != null &&
        !spot.evalResult!.correct &&
        category != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Train this category?'),
          action: SnackBarAction(
            label: 'Train',
            onPressed: () async {
              final tpl = await TrainingPackService.createDrillFromCategory(
                  context, category!);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              }
            },
          ),
        ),
      );
    }
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
