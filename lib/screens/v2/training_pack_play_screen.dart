import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/training_spot.dart';
import '../../models/action_entry.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../../services/evaluation_executor_service.dart';

import '../../helpers/hand_utils.dart';
import '../../helpers/hand_type_utils.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_variant.dart';
import '../../widgets/spot_quiz_widget.dart';
import '../../widgets/common/explanation_text.dart';
import '../../widgets/dynamic_progress_row.dart';
import '../../theme/app_colors.dart';
import '../../services/streak_service.dart';
import '../../services/streak_tracker_service.dart';
import '../../services/notification_service.dart';
import '../../services/mistake_review_pack_service.dart';
import 'training_pack_result_screen_v2.dart';
import '../../services/mistake_categorization_engine.dart';
import '../../models/mistake.dart';
import '../../widgets/poker_table_view.dart' show PlayerAction;
import 'package:uuid/uuid.dart';
import '../../helpers/mistake_advice.dart';
import '../../services/learning_path_progress_service.dart';
import '../../services/learning_path_service.dart';
import '../../services/smart_review_service.dart';
import '../../services/tag_mastery_service.dart';
import '../../services/training_pack_template_builder.dart';
import '../../services/achievement_service.dart';
import '../../services/achievement_trigger_engine.dart';
import '../../services/training_session_service.dart';
import '../training_recommendation_screen.dart';
import '../../services/pack_dependency_map.dart';
import '../../services/pack_library_loader_service.dart';
import '../../services/smart_stage_unlock_engine.dart';
import '../../services/mistake_tag_classifier.dart';
import '../../services/mistake_tag_cluster_service.dart';
import '../../core/training/library/training_pack_library_v2.dart';
import '../../models/v2/training_pack_template_v2.dart';
import '../../services/training_session_launcher.dart';
import '../../services/pinned_learning_service.dart';
import 'training_pack_play_core.dart';
import '../../utils/snackbar_util.dart';

class TrainingPackPlayScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final TrainingPackVariant? variant;
  final List<TrainingPackSpot>? spots;
  const TrainingPackPlayScreen({
    super.key,
    required this.template,
    this.variant,
    this.spots,
    TrainingPackTemplate? original,
  }) : original = original ?? template;

  @override
  State<TrainingPackPlayScreen> createState() => _TrainingPackPlayScreenState();
}

class _TrainingPackPlayScreenState extends State<TrainingPackPlayScreen>
    with TrainingPackPlayCore<TrainingPackPlayScreen> {
  late List<TrainingPackSpot> _spots;
  Map<String, String> _results = {};
  int _index = 0;
  bool _loading = true;
  PlayOrder _order = PlayOrder.sequential;
  int _streetCount = 0;
  final Map<String, int> _handCounts = {};
  final Map<String, int> _handTotals = {};
  bool _summaryShown = false;
  bool _autoAdvance = false;
  SpotFeedback? _feedback;
  Timer? _feedbackTimer;

  @override
  TrainingPackTemplate get template => widget.template;

  @override
  List<TrainingPackSpot> get spots => _spots;

  @override
  set spots(List<TrainingPackSpot> value) => _spots = value;

  @override
  Map<String, String> get results => _results;

  @override
  set results(Map<String, String> value) => _results = value;

  @override
  int get index => _index;

  @override
  set index(int value) => _index = value;

  @override
  bool get loading => _loading;

  @override
  set loading(bool value) => _loading = value;

  @override
  PlayOrder get order => _order;

  @override
  set order(PlayOrder value) => _order = value;

  @override
  int get streetCount => _streetCount;

  @override
  set streetCount(int value) => _streetCount = value;

  @override
  Map<String, int> get handCounts => _handCounts;

  @override
  Map<String, int> get handTotals => _handTotals;

  @override
  bool get summaryShown => _summaryShown;

  @override
  set summaryShown(bool value) => _summaryShown = value;

  @override
  bool get autoAdvance => _autoAdvance;

  @override
  set autoAdvance(bool value) => _autoAdvance = value;

  @override
  SpotFeedback? get feedback => _feedback;

  @override
  set feedback(SpotFeedback? value) => _feedback = value;

  @override
  Timer? get feedbackTimer => _feedbackTimer;

  @override
  set feedbackTimer(Timer? value) => _feedbackTimer = value;

  @override
  void initState() {
    super.initState();
    unawaited(
      PinnedLearningService.instance.recordOpen('pack', widget.template.id),
    );
    _prepare();
  }

  Future<void> _prepare() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoAdvance = prefs.getBool('auto_adv_${widget.template.id}') ?? false;
    });
    final seqKey = 'tpl_seq_${widget.template.id}';
    final resKey = 'tpl_res_${widget.template.id}';
    if (prefs.containsKey(seqKey) || prefs.containsKey(resKey)) {
      await _load();
    } else {
      await _startNew();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seqKey = 'tpl_seq_${widget.template.id}';
    final progKey = 'tpl_prog_${widget.template.id}';
    final resKey = 'tpl_res_${widget.template.id}';
    final streetKey = 'tpl_street_${widget.template.id}';
    final handKey = 'tpl_hand_${widget.template.id}';
    final seq = prefs.getStringList(seqKey);
    var spots = List<TrainingPackSpot>.from(widget.spots ?? widget.template.spots);
    if (seq != null && seq.length == spots.length) {
      final map = {for (final s in spots) s.id: s};
      final ordered = <TrainingPackSpot>[];
      for (final id in seq) {
        final s = map[id];
        if (s != null) ordered.add(s);
      }
      if (ordered.length == spots.length) spots = ordered;
    }
    final resStr = prefs.getString(resKey);
    Map<String, String> results = {};
    if (resStr != null) {
      final data = jsonDecode(resStr);
      if (data is Map) {
        results = {for (final e in data.entries) e.key as String: e.value.toString()};
      }
    }
    int streetCount = 0;
    final handCounts = <String, int>{};
    _handTotals.clear();
    if (widget.template.targetStreet != null) {
      for (final id in results.keys) {
        final s = spots.firstWhereOrNull((e) => e.id == id);
        if (s != null && matchStreet(s)) streetCount++;
      }
      streetCount = max(streetCount, prefs.getInt(streetKey) ?? 0);
    }
    if (widget.template.focusHandTypes.isNotEmpty) {
      for (final g in widget.template.focusHandTypes) {
        handCounts[g.label] = 0;
        for (final s in spots) {
          final code = handCode(s.hand.heroCards);
          if (code != null && matchHandTypeLabel(g.label, code)) {
            _handTotals[g.label] = (_handTotals[g.label] ?? 0) + 1;
          }
        }
      }
      for (final id in results.keys) {
        final s = spots.firstWhereOrNull((e) => e.id == id);
        if (s != null) {
          for (final g in widget.template.focusHandTypes) {
            final code = handCode(s.hand.heroCards);
            if (code != null && matchHandTypeLabel(g.label, code)) {
              handCounts[g.label] = (handCounts[g.label] ?? 0) + 1;
            }
          }
        }
      }
      final saved = prefs.getString(handKey);
      if (saved != null) {
        final data = jsonDecode(saved);
        if (data is Map) {
          for (final e in data.entries) {
            final k = e.key as String;
            final v = (e.value as num).toInt();
            if (handCounts.containsKey(k)) {
              handCounts[k] = max(handCounts[k] ?? 0, v);
            }
          }
        } else if (data is int && widget.template.focusHandTypes.isNotEmpty) {
          final k = widget.template.focusHandTypes.first.label;
          handCounts[k] = max(handCounts[k] ?? 0, data);
        }
      }
    }
    setState(() {
      _spots = spots;
      _results = results;
      _index = prefs.getInt(progKey)?.clamp(0, spots.length - 1) ?? 0;
      _streetCount = streetCount;
      _handCounts
        ..clear()
        ..addAll(handCounts);
      _loading = false;
    });
  }


  Future<void> _startNew() async {
    var spots = List<TrainingPackSpot>.from(widget.spots ?? widget.template.spots);
    if (_order == PlayOrder.random) {
      spots.shuffle();
    } else if (_order == PlayOrder.mistakes) {
      spots = spots.where((s) {
        final exp = _expected(s);
        final ans = _results[s.id];
        return exp != null &&
            ans != null &&
            ans != 'false' &&
            exp.toLowerCase() != ans.toLowerCase();
      }).toList();
      if (spots.isEmpty) spots = List<TrainingPackSpot>.from(widget.spots ?? widget.template.spots);
    }
    setState(() {
      _spots = spots;
      _index = 0;
      _streetCount = 0;
      _summaryShown = false;
      _handCounts
        ..clear()
        ..addEntries(widget.template.focusHandTypes.map((e) => MapEntry(e.label, 0)));
      _loading = false;
    });
    await save();
  }

  String? _expected(TrainingPackSpot spot) {
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }

  List<String> _heroActions(TrainingPackSpot spot) {
    final acts = spot.hand.actions[0] ?? [];
    final hero = spot.hand.heroIndex;
    final res = <String>[];
    for (final a in acts) {
      if (a.playerIndex == hero) {
        final name = a.action.toLowerCase();
        if (!res.contains(name)) res.add(name);
      }
    }
    return res;
  }

  bool _matchHandTypeLabel(TrainingPackSpot spot, String label) {
    final code = handCode(spot.hand.heroCards);
    if (code == null) return false;
    return matchHandTypeLabel(label, code);
  }

  bool _matchHandType(TrainingPackSpot spot) {
    for (final g in widget.template.focusHandTypes) {
      if (_matchHandTypeLabel(spot, g.label)) return true;
    }
    return false;
  }


  double? _actionEv(TrainingPackSpot spot, String action) {
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _actionIcmEv(TrainingPackSpot spot, String action) {
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.icmEv;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot spot) {
    double? best;
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best, a.ev!);
      }
    }
    return best;
  }

  double? _bestIcmEv(TrainingPackSpot spot) {
    double? best;
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex && a.icmEv != null) {
        best = best == null ? a.icmEv! : max(best, a.icmEv!);
      }
    }
    return best;
  }

  PlayerAction _parseAction(String a) {
    switch (a.toLowerCase()) {
      case 'fold':
        return PlayerAction.fold;
      case 'call':
        return PlayerAction.call;
      case 'push':
        return PlayerAction.push;
      case 'raise':
      case 'bet':
        return PlayerAction.raise;
      case 'post':
        return PlayerAction.post;
    }
    return PlayerAction.none;
  }

  List<String> _wrongIds() {
    final ids = <String>[];
    for (final s in widget.template.spots) {
      final exp = _expected(s);
      final ans = _results[s.id];
      if (exp != null && ans != null && ans != 'false' && exp.toLowerCase() != ans.toLowerCase()) {
        ids.add(s.id);
      }
    }
    return ids;
  }

  TrainingSpot _toSpot(TrainingPackSpot spot) {
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
    return TrainingSpot(
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
  }

  void _showFeedback(TrainingPackSpot spot, String action, double? heroEv,
      double? evDiff, double? icmDiff, bool correct, bool repeated) {
    _feedbackTimer?.cancel();
    final advice =
        spot.tags.isNotEmpty ? kMistakeAdvice[spot.tags.first] : null;
    setState(() {
      _feedback = SpotFeedback(
          action, heroEv, evDiff, icmDiff, correct, repeated, advice);
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _hideFeedback();
    });
  }

  void _hideFeedback() {
    _feedbackTimer?.cancel();
    if (_feedback != null) {
      setState(() => _feedback = null);
    }
  }

  String _fmt(double? v, [String suffix = '']) {
    if (v == null) return '--';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}$suffix';
  }


  Future<bool> _confirmStartOver(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start over?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    return context.mounted && res == true;
  }

  Future<void> _saveCurrentSpot() async {
    await context
        .read<MistakeReviewPackService>()
        .addSpot(widget.original, _spots[_index]);
    if (mounted) {
      SnackbarUtil.showMessage(context, 'Сохранено в Повторы ошибок');
    }
  }

  Future<void> _showCompletion() async {
    if (_summaryShown) return;
    _summaryShown = true;
    await LearningPathProgressService.instance
        .markCompleted(widget.original.id);
    await SmartStageUnlockEngine.instance.checkAndUnlockNextStage();
    final newly =
        await PackDependencyMap.instance.getUnlockedAfter(widget.original.id);
    if (newly.isNotEmpty && mounted) {
      final lib = PackLibraryLoaderService.instance.library;
      for (final id in newly) {
        final pack = lib.firstWhereOrNull((p) => p.id == id);
        if (pack != null) {
          SnackbarUtil.showMessage(context, '\uD83D\uDD13 Новый пак разблокирован: ${pack.name}');
        }
      }
    }
    final isFinalStep =
        widget.original.tags.contains('starterPath') &&
            widget.original.tags.contains('step5');
    if (widget.original.tags.contains('starterPath')) {
      await LearningPathService.instance.advance(widget.original.id);
    }
    final spots = widget.spots ?? widget.template.spots;
    final tpl = widget.template.copyWith(spots: spots);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackResultScreenV2(
          template: tpl,
          original: widget.original,
          results: Map<String, String>.from(_results),
        ),
      ),
    );
    final ctx = navigatorKey.currentContext;
    if (ctx != null && isFinalStep) {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('post_starter_path_choice')) {
        final choice = await showDialog<String>(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            title: const Text('Какой следующий шаг вам подойдёт?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, 'mistakes'),
                child: const Text('Повторить ошибки'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dCtx, 'weak'),
                child: const Text('Прокачать слабости'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dCtx, 'custom'),
                child: const Text('Кастомный путь'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Не сейчас'),
              ),
            ],
          ),
        );
        if (choice != null) {
          await prefs.setString('post_starter_path_choice', choice);
          if (choice == 'mistakes') {
            await SmartReviewService.instance.buildMistakePack(ctx);
          } else if (choice == 'weak') {
            const builder = TrainingPackTemplateBuilder();
            final mastery = ctx.read<TagMasteryService>();
            final weakTpl = await builder.buildWeaknessPack(mastery);
            await ctx
                .read<TrainingSessionService>()
                .startSession(weakTpl, persist: false);
            await Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => const TrainingSessionScreen()),
            );
          } else if (choice == 'custom') {
            await Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => const TrainingRecommendationScreen()),
            );
          }
        }
      }
    }
    AchievementService.instance.checkAll();
    await AchievementTriggerEngine.instance.checkAndTriggerAchievements();
  }

  Future<void> _next() async {
    _hideFeedback();
    if (_index + 1 < _spots.length) {
      setState(() => _index++);
      save();
    } else {
      _index = _spots.length - 1;
      save();
      await context.read<StreakService>().onFinish();
      await context
          .read<StreakTrackerService>()
          .markActiveToday(context);
      await NotificationService.cancel(101);
      await NotificationService.cancel(102);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_training_day',
          DateTime.now().toIso8601String().split('T').first);
      await NotificationService.scheduleDailyReminder(context);
      await NotificationService.scheduleDailyProgress(context);
      final ids = _wrongIds();
      if (ids.isNotEmpty) {
        final template = widget.template.copyWith(
          id: const Uuid().v4(),
          name: 'Review mistakes',
          spots: [for (final s in widget.template.spots) if (ids.contains(s.id)) s],
        );
        MistakeReviewPackService.setLatestTemplate(template);
        await context
            .read<MistakeReviewPackService>()
            .addPack(ids, templateId: widget.original.id);
        final start = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Review mistakes now?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(_, false),
                  child: const Text('Later')),
              TextButton(
                  onPressed: () => Navigator.pop(_, true),
                  child: const Text('Start')),
            ],
          ),
        );
        if (!mounted) return;
        if (start == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TrainingPackPlayScreen(
                template: MistakeReviewPackService.cachedTemplate!,
                original: null,
              ),
            ),
          );
          return;
        }
      }
      await _showCompletion();
    }
  }

  Future<void> _choose(String? act) async {
    final spot = _spots[_index];
    if (act != null) {
      final first = !_results.containsKey(spot.id);
      _results[spot.id] = act.toLowerCase();
      if (first && matchStreet(spot)) _streetCount++;
      if (first) {
        for (final g in widget.template.focusHandTypes) {
          if (_matchHandTypeLabel(spot, g.label)) {
            _handCounts[g.label] = (_handCounts[g.label] ?? 0) + 1;
          }
        }
      }

      final evalSpot = _toSpot(spot);
      final evaluation = context
          .read<EvaluationExecutorService>()
          .evaluateSpot(context, evalSpot, act);
      final heroEv = _actionEv(spot, act);
      final bestEv = _bestEv(spot);
      final heroIcm = _actionIcmEv(spot, act);
      final bestIcm = _bestIcmEv(spot);
      final evDiff =
          heroEv != null && bestEv != null ? heroEv - bestEv : null;
      final icmDiff =
          heroIcm != null && bestIcm != null ? heroIcm - bestIcm : null;
      final goodEv = evDiff == null || evDiff >= 0;
      final goodIcm = icmDiff == null || icmDiff >= 0;
      if (goodEv && goodIcm) {
        HapticFeedback.lightImpact();
      } else if (!goodEv && !goodIcm) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      final incorrect =
          (evDiff != null && evDiff < 0) ||
          (icmDiff != null && icmDiff < 0) ||
          !evaluation.correct;
      TrainingPackTemplateV2? booster;
      String? category;
      if (incorrect) {
        const engine = MistakeCategorizationEngine();
        final strength = engine.computeHandStrength(spot.hand.heroCards);
        final m = Mistake(
          spot: spot,
          action: _parseAction(act),
          handStrength: strength,
        );
        category = engine.categorize(m);

        final attempt = TrainingSpotAttempt(
          spot: spot,
          userAction: act,
          correctAction: expected,
          evDiff: evDiff ?? 0,
        );
        final cls = const MistakeTagClassifier().classify(attempt);
        if (cls != null && cls.severity >= 0.8) {
          await TrainingPackLibraryV2.instance.loadFromFolder();
          final cluster =
              const MistakeTagClusterService().getClusterForTag(cls.tag);
          final tag = cluster.label.toLowerCase();
          booster = TrainingPackLibraryV2.instance.packs.firstWhereOrNull(
            (p) =>
                p.meta['type'] == 'booster' &&
                (p.meta['tag']?.toString().toLowerCase() == tag),
          );
        }
      }
      final repeated = incorrect &&
          context
              .read<MistakeReviewPackService>()
              .packs
              .any((p) => p.spotIds.contains(spot.id));
      if (incorrect && first) {
        await context
            .read<MistakeReviewPackService>()
            .addSpot(widget.original, spot);
        if (mounted) {
          SnackbarUtil.showMessage(context, 'Сохранено в Повторы ошибок');
        }
      }
      if (_autoAdvance && !incorrect) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _next();
        return;
      }

      final expected = evaluation.expectedAction;
      final explanation = spot.note.trim().isNotEmpty
          ? spot.note.trim()
          : (evaluation.hint ?? spot.evalResult?.hint ?? '');

      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExplanationText(
                selectedAction: act,
                correctAction: expected,
                explanation: explanation,
                category: category,
                evLoss: evDiff != null && evDiff < 0 ? -evDiff : null,
              ),
              if (booster != null) ...[
                SizedBox(height: 12 * scale),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    const TrainingSessionLauncher().launch(booster!);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 Fix this leak',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              if (category != null) ...[
                SizedBox(height: 12 * scale),
                ElevatedButton(
                  onPressed: () async {
                    final tpl = await TrainingPackService.createDrillFromCategory(
                        context, category!);
                    if (tpl == null) return;
                    await context.read<TrainingSessionService>().startSession(tpl);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrainingSessionScreen()),
                      );
                    }
                  },
                  child: Text('Тренироваться на похожих',
                      style: TextStyle(fontSize: 14 * scale)),
                ),
              ],
              SizedBox(height: 16 * scale),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text('Continue', style: TextStyle(fontSize: 14 * scale)),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      _showFeedback(spot, _expected(spot) ?? '', heroEv, evDiff, icmDiff,
          evaluation.correct, repeated);
    }
    if (!_autoAdvance) await _next();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(0.8, 1.0);
    final spot = _spots[_index];
    final progress = (_index + 1) / _spots.length;
    final actions = _heroActions(spot);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Exit training? Your progress will be saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              save();
              Navigator.pop(context);
            }
          },
        ),
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _saveCurrentSpot,
          ),
          IconButton(
            tooltip: 'Auto-Advance on Correct',
            icon: Icon(Icons.bolt,
                color: _autoAdvance
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white70),
            onPressed: () async {
              setState(() => _autoAdvance = !_autoAdvance);
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('auto_adv_${widget.template.id}', _autoAdvance);
            },
          ),
          PopupMenuButton<dynamic>(
            initialValue: _order,
            onSelected: (choice) async {
              if (choice == 'start') {
                final ok = await _confirmStartOver(context);
                if (ok) {
                  setState(() {
                    _index = 0;
                    _results.clear();
                  });
                  final prefs = await SharedPreferences.getInstance();
                  prefs
                    ..remove('tpl_seq_${widget.template.id}')
                    ..remove('tpl_res_${widget.template.id}')
                    ..remove('tpl_prog_${widget.template.id}');
                  if (widget.template.targetStreet != null) {
                    prefs.remove('tpl_street_${widget.template.id}');
                  }
                  if (widget.template.focusHandTypes.isNotEmpty) {
                    prefs.remove('tpl_hand_${widget.template.id}');
                  }
                  save(ts: false);
                }
              } else if (choice is PlayOrder) {
                setState(() => _order = choice);
                await _startNew();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'start', child: Text('Start over')),
              PopupMenuDivider(),
              PopupMenuItem(value: PlayOrder.sequential, child: Text('Sequential')),
              PopupMenuItem(value: PlayOrder.random, child: Text('Random')),
              PopupMenuItem(value: PlayOrder.mistakes, child: Text('Mistakes')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            widget.original.spots.length > widget.template.spots.length ? 32 : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.original.spots.length > widget.template.spots.length)
                Padding(
                  padding: EdgeInsets.only(bottom: 4 * scale),
                  child: Chip(
                    label: Text(
                      AppLocalizations.of(context)!.reviewMistakesOnly,
                      style: TextStyle(fontSize: 12 * scale),
                    ),
                    backgroundColor: Colors.orange,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              LinearProgressIndicator(value: progress, minHeight: 4 * scale),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              children: [
            if (widget.template.focusTags.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8 * scale),
                child: Text(
                  '🎯 Focus: ${widget.template.focusTags.join(', ')}',
                  style: TextStyle(color: Colors.white70, fontSize: 14 * scale),
                ),
              ),
            if (widget.template.focusHandTypes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎯 Hand Goals',
                        style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
                    for (final g in widget.template.focusHandTypes)
                      Padding(
                        padding: EdgeInsets.only(top: 4 * scale),
                        child: LayoutBuilder(builder: (context, c) {
                          if (c.maxWidth < 320) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: _handTotals[g.label] != null && _handTotals[g.label]! > 0
                                      ? (_handCounts[g.label]?.clamp(0, _handTotals[g.label]!) ?? 0) /
                                          _handTotals[g.label]!
                                      : 0,
                                  color: Colors.purpleAccent,
                                  backgroundColor: Colors.purpleAccent.withOpacity(0.3),
                                  minHeight: 6 * scale,
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  '${g.label}: ${_handCounts[g.label] ?? 0}/${_handTotals[g.label] ?? 0}',
                                  style: TextStyle(color: Colors.white70, fontSize: 14 * scale),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _handTotals[g.label] != null && _handTotals[g.label]! > 0
                                      ? (_handCounts[g.label]?.clamp(0, _handTotals[g.label]!) ?? 0) /
                                          _handTotals[g.label]!
                                      : 0,
                                  color: Colors.purpleAccent,
                                  backgroundColor: Colors.purpleAccent.withOpacity(0.3),
                                  minHeight: 6 * scale,
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              Text(
                                '${g.label}: ${_handCounts[g.label] ?? 0}/${_handTotals[g.label] ?? 0}',
                                style: TextStyle(color: Colors.white70, fontSize: 14 * scale),
                              ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
            if (widget.template.heroRange != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8 * scale),
                child: Text(
                  widget.template.handTypeSummary(),
                  style: TextStyle(color: Colors.white54, fontSize: 14 * scale),
                ),
              ),
            Text('Spot ${_index + 1} of ${_spots.length}',
                style: TextStyle(color: Colors.white70, fontSize: 14 * scale)),
            SizedBox(height: 8 * scale),
            const DynamicProgressRow(),
            SizedBox(height: 8 * scale),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if (d.primaryVelocity != null &&
                      d.primaryVelocity! < -100 &&
                      _results[spot.id] == null) {
                    _choose(null);
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_index),
                  children: [
                    SpotQuizWidget(spot: spot),
                    SizedBox(height: 16 * scale),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final a in actions.isEmpty
                            ? ['fold', 'push', 'call']
                            : (actions.length == 1 && !actions.contains('fold')
                                ? [...actions, 'fold']
                                : actions))
                          _results[spot.id]?.toLowerCase() == a.toLowerCase()
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent),
                                  onPressed: () => _choose(a),
                                  child: Text(a.toUpperCase(),
                                      style: TextStyle(fontSize: 14 * scale)),
                                )
                              : OutlinedButton(
                                  onPressed: () => _choose(a),
                                  child: Text(a.toUpperCase(),
                                      style: TextStyle(fontSize: 14 * scale)),
                                ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
          if (_feedback != null)
            Positioned(
              top: 16 * scale,
              left: 16 * scale,
              right: 16 * scale,
              child: GestureDetector(
                onTap: _hideFeedback,
                child: Card(
                  color: _feedback!.correct ? Colors.green : Colors.red,
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_feedback!.repeated)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 2 * scale),
                            color: Colors.redAccent,
                            child: Text(
                              'Repeated Mistake',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14 * scale),
                            ),
                          ),
                        Text(
                          'Correct: ${_feedback!.action.toUpperCase()}',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * scale),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          "EV: ${_fmt(_feedback!.heroEv, ' BB')}  \u0394EV: ${_fmt(_feedback!.evDiff, ' BB')}${_feedback!.icmDiff != null ? '  \u0394ICM: ${_fmt(_feedback!.icmDiff)}' : ''}",
                          style: TextStyle(color: Colors.white, fontSize: 14 * scale),
                        ),
                        if (_feedback!.advice != null) ...[
                          SizedBox(height: 4 * scale),
                          Text(
                            _feedback!.advice!,
                            style: TextStyle(color: Colors.white70, fontSize: 14 * scale),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
