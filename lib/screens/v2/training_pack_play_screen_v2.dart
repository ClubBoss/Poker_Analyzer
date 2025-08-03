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
import '../../widgets/poker_table_view.dart';
import '../../widgets/training_pack_play_screen_v2_toolbar.dart';
import '../../services/app_settings_service.dart';
import 'package:uuid/uuid.dart';
import '../../helpers/mistake_advice.dart';
import '../../services/user_preferences_service.dart';
import 'package:provider/provider.dart';
import '../../services/pinned_learning_service.dart';
import 'training_pack_play_core.dart';
import '../../utils/snackbar_util.dart';

class TrainingPackPlayScreenV2 extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final TrainingPackVariant? variant;
  final List<TrainingPackSpot>? spots;
  const TrainingPackPlayScreenV2({
    super.key,
    required this.template,
    this.variant,
    this.spots,
    TrainingPackTemplate? original,
  }) : original = original ?? template;

  @override
  State<TrainingPackPlayScreenV2> createState() => _TrainingPackPlayScreenV2State();
}

class _TrainingPackPlayScreenV2State extends State<TrainingPackPlayScreenV2>
    with TrainingPackPlayCore<TrainingPackPlayScreenV2> {
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
  late bool _showActionHints;
  String? _pressedAction;
  int _street = 0;
  bool _streetAnswered = false;

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

  int get _targetStreetIndex {
    switch (widget.template.targetStreet) {
      case 'flop':
        return 1;
      case 'turn':
        return 2;
      case 'river':
        return 3;
      case 'preflop':
        return 0;
      default:
        return 0;
    }
  }

  int get _currentStreet =>
      widget.template.targetStreet != null ? _targetStreetIndex : _street;

  @override
  void initState() {
    super.initState();
    unawaited(
      PinnedLearningService.instance.recordOpen('pack', widget.template.id),
    );
    _prepare();
    _showActionHints = context.read<UserPreferencesService>().showActionHints;
  }

  Future<void> _prepare() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoAdvance =
          widget.template.targetStreet == null &&
              (prefs.getBool('auto_adv_${widget.template.id}') ?? false);
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
        final base = id.split('_street').first;
        final s = spots.firstWhereOrNull((e) => e.id == base);
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
        final base = id.split('_street').first;
        final s = spots.firstWhereOrNull((e) => e.id == base);
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
      _street = widget.template.targetStreet != null ? _targetStreetIndex : 0;
      _streetAnswered = false;
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
      _street = widget.template.targetStreet != null ? _targetStreetIndex : 0;
      _streetAnswered = false;
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
    final idx = widget.template.targetStreet != null ? _targetStreetIndex : 0;
    final acts = spot.hand.actions[idx] ?? [];
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

  List<String> _heroActionsStreet(TrainingPackSpot spot, int street) {
    final acts = spot.hand.actions[street] ?? [];
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
    final streets = spot.evalResult?.streets;
    if (streets != null && _currentStreet < streets.length) {
      final data = streets[_currentStreet];
      final val = data[action] ?? data[action.toLowerCase()];
      if (val is num) return val.toDouble();
      if (val is Map && val['ev'] is num) return (val['ev'] as num).toDouble();
    }
    for (final a in spot.hand.actions[_currentStreet] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _actionIcmEv(TrainingPackSpot spot, String action) {
    final streets = spot.evalResult?.streets;
    if (streets != null && _currentStreet < streets.length) {
      final data = streets[_currentStreet];
      final val = data['${action.toLowerCase()}Icm'] ?? data['${action.toLowerCase()}_icm'];
      if (val is num) return val.toDouble();
      if (val is Map && val['icmEv'] is num) return (val['icmEv'] as num).toDouble();
    }
    for (final a in spot.hand.actions[_currentStreet] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.icmEv;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot spot) {
    final streets = spot.evalResult?.streets;
    if (streets != null && _currentStreet < streets.length) {
      double? best;
      final data = streets[_currentStreet];
      for (final v in data.values) {
        final ev = v is num
            ? v.toDouble()
            : (v is Map && v['ev'] is num ? (v['ev'] as num).toDouble() : null);
        if (ev != null) best = best == null ? ev : max(best, ev);
      }
      return best;
    }
    double? best;
    for (final a in spot.hand.actions[_currentStreet] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best, a.ev!);
      }
    }
    return best;
  }

  double? _bestIcmEv(TrainingPackSpot spot) {
    final streets = spot.evalResult?.streets;
    if (streets != null && _currentStreet < streets.length) {
      double? best;
      final data = streets[_currentStreet];
      for (final v in data.values) {
        final ev = v is Map && v['icmEv'] is num
            ? (v['icmEv'] as num).toDouble()
            : null;
        if (ev != null) best = best == null ? ev : max(best, ev);
      }
      return best;
    }
    double? best;
    for (final a in spot.hand.actions[_currentStreet] ?? []) {
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

  void _nextStreet() {
    if (widget.template.targetStreet != null) return;
    setState(() {
      _street++;
      _streetAnswered = false;
    });
  }

  Future<void> _handleAction(String action) async {
    if (_showActionHints) {
      await context.read<UserPreferencesService>().setShowActionHints(false);
      if (mounted) setState(() => _showActionHints = false);
    }
    setState(() => _pressedAction = action);
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _pressedAction = null);
    await _choose(action);
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
  }

  Future<void> _next() async {
    _hideFeedback();
    if (_index + 1 < _spots.length) {
      setState(() {
        _index++;
        _street =
            widget.template.targetStreet != null ? _targetStreetIndex : 0;
        _streetAnswered = false;
      });
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
      final key = spot.streetMode ? '${spot.id}_street\$_street' : spot.id;
      final first = !_results.containsKey(key);
      _results[key] = act.toLowerCase();
      if (first && (!spot.streetMode || _street == spot.street) &&
          matchStreet(spot)) {
        _streetCount++;
      }
      if (first) {
        for (final g in widget.template.focusHandTypes) {
          if (_matchHandTypeLabel(spot, g.label)) {
            _handCounts[g.label] = (_handCounts[g.label] ?? 0) + 1;
          }
        }
      }

      if (spot.streetMode &&
          widget.template.targetStreet == null &&
          _currentStreet < spot.street) {
        _streetAnswered = true;
        save();
        if (_autoAdvance) {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          _nextStreet();
        }
        return;
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
    final actions = spot.streetMode
        ? _heroActionsStreet(spot, _currentStreet)
        : _heroActions(spot);
    final pushAction = actions.isEmpty ? 'push' : actions.first;
    return Scaffold(
      backgroundColor: const Color(0xFF1B1C1E),
      body: Builder(builder: (context) {
        final heroCards = spot.hand.heroCards
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
            .toList();
        final boardCards = [
          for (final c in spot.hand.boardCardsForStreet(_currentStreet))
            CardModel(rank: c[0], suit: c.substring(1))
        ];
        final count = spot.hand.playerCount;
        final names = [for (int i = 0; i < count; i++) 'P${i + 1}'];
        final stacks = [for (int i = 0; i < count; i++) spot.hand.stacks['$i']?.toDouble() ?? 0.0];
        final hint = spot.note.trim().isNotEmpty
            ? spot.note.trim()
            : (spot.evalResult?.hint ?? '');
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TrainingPackPlayScreenV2Toolbar(
                title: widget.template.name,
                index: _index,
                total: _spots.length,
                streetIndex: spot.streetMode ? _currentStreet : null,
                onExit: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title:
                          const Text('Exit training? Your progress will be saved.'),
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
                onModeToggle: () async {
                  final val = !AppSettingsService.instance.useIcm;
                  await AppSettingsService.instance.setUseIcm(val);
                  setState(() {});
                },
                mini: scale < 0.9,
              ),
            ),
            IgnorePointer(
              child: PokerTableView(
                heroIndex: spot.hand.heroIndex,
                playerCount: count,
                playerNames: names,
                playerStacks: stacks,
                playerActions: List.filled(count, PlayerAction.none),
                playerBets: List.filled(count, 0.0),
                onHeroSelected: (_) {},
                onStackChanged: (_, __) {},
                onNameChanged: (_, __) {},
                onBetChanged: (_, __) {},
                onActionChanged: (_, __) {},
                potSize: 0,
                onPotChanged: (_) {},
                heroCards: heroCards,
                revealedCards: const [],
                boardCards: boardCards,
                currentStreet: _currentStreet,
                showPlayerActions: true,
                scale: scale,
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! > 0) {
                    _handleAction(pushAction);
                  } else if (details.primaryVelocity! < 0) {
                    _handleAction('fold');
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _handleAction('fold'),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 100),
                          scale: _pressedAction == 'fold' ? 0.95 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showActionHints ? 0.3 : 0.0,
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.black26,
                              child: Text(
                                'FOLD',
                                style: TextStyle(
                                  fontSize: 24 * scale,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _handleAction(pushAction),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 100),
                          scale: _pressedAction == pushAction ? 0.95 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showActionHints ? 0.3 : 0.0,
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.black26,
                              child: Text(
                                pushAction.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24 * scale,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_feedback != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1,
                  child: GestureDetector(
                    onTap: _hideFeedback,
                    child: Card(
                      color: _feedback!.correct ? Colors.green : Colors.red,
                      child: Padding(
                        padding: EdgeInsets.all(8 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Correct: ${_feedback!.action.toUpperCase()}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "EV: ${_fmt(_feedback!.heroEv, ' BB')}  \u0394EV: ${_fmt(_feedback!.evDiff, ' BB')}${_feedback!.icmDiff != null ? '  \u0394ICM: ${_fmt(_feedback!.icmDiff)}' : ''}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            if (_feedback!.advice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(_feedback!.advice!,
                                    style: const TextStyle(color: Colors.white70)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (hint.isNotEmpty &&
                _results[spot.streetMode ? '${spot.id}_street\$_street' : spot.id] ==
                    null)
              Positioned(
                bottom: 72,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: Text(hint,
                        style:
                            const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ),
                ),
            if (widget.template.targetStreet == null &&
                spot.streetMode &&
                _streetAnswered &&
                _currentStreet < spot.street)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _nextStreet,
                    child: const Text('Next Street'),
                  ),
                ),
              ),
            if (_showActionHints)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: const Text(
                      'Тапните влево или вправо, чтобы выбрать действие',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ],
        );
      }),
    );
  }
}
