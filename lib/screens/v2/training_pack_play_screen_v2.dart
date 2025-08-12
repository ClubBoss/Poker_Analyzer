import 'dart:async';

import 'training_pack_play_base.dart';
import 'training_pack_result_screen_v2.dart';
import '../../widgets/training_pack_play_screen_v2_toolbar.dart';
import '../../services/analytics_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/adaptive_spot_scheduler.dart';
import '../../services/user_error_rate_service.dart';
import '../../services/spaced_review_service.dart';
import '../../services/sr_queue_builder.dart';
import '../../services/pinned_learning_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingPackPlayScreenV2 extends TrainingPackPlayBase {
  const TrainingPackPlayScreenV2({
    super.key,
    required super.template,
    super.variant,
    super.spots,
    TrainingPackTemplate? original,
  }) : super(original: original);

  @override
  State<TrainingPackPlayScreenV2> createState() =>
      _TrainingPackPlayScreenV2State();
}

class _TrainingPackPlayScreenV2State
    extends TrainingPackPlayBaseState<TrainingPackPlayScreenV2> {
  static const int _kInterleaveCadence = 2;
  List<TrainingPackSpot> get _spots => spots;
  set _spots(List<TrainingPackSpot> value) => spots = value;
  Map<String, String> get _results => results;
  set _results(Map<String, String> value) => results = value;
  int get _index => index;
  set _index(int value) => index = value;
  bool get _loading => loading;
  set _loading(bool value) => loading = value;
  PlayOrder get _order => order;
  set _order(PlayOrder value) => order = value;
  int get _streetCount => streetCount;
  set _streetCount(int value) => streetCount = value;
  Map<String, int> get _handCounts => handCounts;
  Map<String, int> get _handTotals => handTotals;
  bool get _summaryShown => summaryShown;
  set _summaryShown(bool value) => summaryShown = value;
  bool get _autoAdvance => autoAdvance;
  set _autoAdvance(bool value) => autoAdvance = value;
  SpotFeedback? get _feedback => feedback;
  set _feedback(SpotFeedback? value) => feedback = value;
  Timer? get _feedbackTimer => feedbackTimer;
  set _feedbackTimer(Timer? value) => feedbackTimer = value;
  late bool _showActionHints;
  String? _pressedAction;
  int _street = 0;
  bool _streetAnswered = false;
  bool _adaptiveMode = true;
  late AdaptiveSpotScheduler _scheduler;
  final List<TrainingPackSpot> _pool = [];
  final List<String> _recent = [];
  bool _srEnabled = true;
  final List<SRQueueItem> _srQueue = [];
  SRQueueItem? _srCurrent;
  int _srCounter = 0;
  bool _srShowCTA = false;
  bool _srUptakeLogged = false;

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
      _adaptiveMode = prefs.getBool('adaptive_mode_enabled') ?? true;
      _srEnabled = prefs.getBool('interleave_sr_enabled') ?? true;
    });
    final seqKey = 'tpl_seq_${widget.template.id}';
    final resKey = 'tpl_res_${widget.template.id}';
    if (prefs.containsKey(seqKey) || prefs.containsKey(resKey)) {
      await _load();
    } else {
      await _startNew();
    }
    final sr = context.read<SpacedReviewService>();
    final queue = _srEnabled
        ? buildSrQueue(
            sr,
            {
              ..._spots.map((s) => s.id),
              ..._pool.map((s) => s.id),
              ...widget.template.spots.map((s) => s.id),
            }.toSet(),
          )
        : const <SRQueueItem>[];
    setState(() {
      _srQueue
        ..clear()
        ..addAll(queue);
      _srShowCTA = _srQueue.isNotEmpty;
    });
  }

  Future<void> _toggleAdaptive() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _adaptiveMode = !_adaptiveMode);
    await prefs.setBool('adaptive_mode_enabled', _adaptiveMode);
  }

  Future<void> _toggleSRInterleave() async {
    final prefs = await SharedPreferences.getInstance();
    final enabling = !_srEnabled;
    setState(() => _srEnabled = enabling);
    await prefs.setBool('interleave_sr_enabled', _srEnabled);
    unawaited(AnalyticsService.instance
        .logEvent('sr_interleave_enabled_toggled', {'enabled': _srEnabled}));
    if (enabling) {
      final sr = context.read<SpacedReviewService>();
      final queue = buildSrQueue(
        sr,
        {
          ..._spots.map((s) => s.id),
          ..._pool.map((s) => s.id),
          ...widget.template.spots.map((s) => s.id),
        }.toSet(),
      );
      setState(() {
        _srQueue
          ..clear()
          ..addAll(queue);
        _srShowCTA = _srQueue.isNotEmpty;
      });
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

  void _maybeInjectSR({bool force = false}) {
    if (!_srEnabled || _srQueue.isEmpty) return;
      if (!force && _srCounter < _kInterleaveCadence) return;
    final item = _srQueue.removeAt(0);
    setState(() {
      _srCurrent = item;
      _srCounter = 0;
      _srShowCTA = _srQueue.isNotEmpty;
    });
    unawaited(AnalyticsService.instance.logEvent('sr_interleave_injected', {
      'spotId': item.spot.id,
      'packId': item.packId,
        'cadence': force ? 0 : _kInterleaveCadence,
    }));
    if (!_srUptakeLogged) {
      unawaited(AnalyticsService.instance.logEvent('sr_interleave_uptake', {}));
      _srUptakeLogged = true;
    }
  }


  Future<void> _startNew() async {
    var spots =
        List<TrainingPackSpot>.from(widget.spots ?? widget.template.spots);
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
      if (spots.isEmpty) {
        spots = List<TrainingPackSpot>.from(
            widget.spots ?? widget.template.spots);
      }
    }
    if (_adaptiveMode) {
      _scheduler = AdaptiveSpotScheduler(
        seed: DateTime.now().millisecondsSinceEpoch,
        packTags: spots.expand((e) => e.tags).toSet(),
      );
      _pool
        ..clear()
        ..addAll(spots);
      _spots = [];
      _recent.clear();
      final first = await _scheduler.next(
        packId: widget.template.id,
        pool: _pool,
        recentSpotIds: _recent,
      );
      _spots.add(first);
      _pool.removeWhere((s) => s.id == first.id);
      _recent.add(first.id);
      spots = _spots;
    }
    setState(() {
      _spots = spots;
      _index = 0;
      _street =
          widget.template.targetStreet != null ? _targetStreetIndex : 0;
      _streetAnswered = false;
      _streetCount = 0;
      _summaryShown = false;
      _handCounts
        ..clear()
        ..addEntries(widget.template.focusHandTypes
            .map((e) => MapEntry(e.label, 0)));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено в Повторы ошибок')),
      );
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
    if (_adaptiveMode && _pool.isNotEmpty) {
      final nextSpot = await _scheduler.next(
        packId: widget.template.id,
        pool: _pool,
        recentSpotIds: _recent,
      );
      setState(() {
        _spots.add(nextSpot);
        _pool.removeWhere((s) => s.id == nextSpot.id);
        _index++;
        _street =
            widget.template.targetStreet != null ? _targetStreetIndex : 0;
        _streetAnswered = false;
        _recent.add(nextSpot.id);
        if (_recent.length > AdaptiveSpotScheduler.noRepeatWindow) {
          _recent.removeAt(0);
        }
      });
      save();
      return;
    }
    if (_index + 1 < _spots.length) {
      setState(() {
        _index++;
        _street =
            widget.template.targetStreet != null ? _targetStreetIndex : 0;
        _streetAnswered = false;
      });
      save();
      return;
    }
    _index = _spots.length - 1;
    save();
    await context.read<StreakService>().onFinish();
    await context.read<StreakTrackerService>().markActiveToday(context);
    await NotificationService.cancel(101);
    await NotificationService.cancel(102);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'last_training_day', DateTime.now().toIso8601String().split('T').first);
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

  Future<void> _choose(String? act) async {
    final isSr = _srCurrent != null;
    final spot = isSr ? _srCurrent!.spot : _spots[_index];
    if (act != null) {
      final key = spot.id;
      final first = !isSr && !_results.containsKey(key);
      if (!isSr) {
        _results[key] = act.toLowerCase();
        if (first && matchStreet(spot)) {
          _streetCount++;
        }
        if (first) {
          for (final g in widget.template.focusHandTypes) {
            if (_matchHandTypeLabel(spot, g.label)) {
              _handCounts[g.label] = (_handCounts[g.label] ?? 0) + 1;
            }
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
      final repeated = !isSr &&
          incorrect &&
          context
              .read<MistakeReviewPackService>()
              .packs
              .any((p) => p.spotIds.contains(spot.id));
      await UserErrorRateService.instance.recordAttempt(
        packId: isSr ? _srCurrent!.packId : widget.template.id,
        tags: spot.tags.toSet(),
        isCorrect: !incorrect,
        ts: DateTime.now(),
      );
      if (!isSr && incorrect && first) {
        await context
            .read<MistakeReviewPackService>()
            .addSpot(widget.original, spot);
        await context
            .read<SpacedReviewService>()
            .recordMistake(spot.id, widget.template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сохранено в Повторы ошибок')),
          );
        }
      }
      await context.read<SpacedReviewService>().recordReviewOutcome(
            spot.id,
            isSr ? _srCurrent!.packId : widget.template.id,
            !incorrect);
        if (_autoAdvance && !incorrect && !isSr) {
          _srCounter++;
          if (_srEnabled && _srQueue.isNotEmpty &&
              _srCounter >= _kInterleaveCadence) {
            _maybeInjectSR();
            return;
          }
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
      if (isSr) {
        unawaited(AnalyticsService.instance.logEvent('sr_interleave_completed', {
          'spotId': spot.id,
          'packId': _srCurrent!.packId,
          'correct': !incorrect
        }));
        _srCurrent = null;
        await _next();
        return;
      }
      _srCounter++;
      if (_srEnabled && _srQueue.isNotEmpty &&
          _srCounter >= _kInterleaveCadence) {
        _maybeInjectSR();
        return;
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
    final spot = _srCurrent?.spot ?? _spots[_index];
    // final actions = _heroActions(spot); // uncomment if used later
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
                streetIndex: null,
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
                onAdaptiveToggle: _toggleAdaptive,
                onSRToggle: _toggleSRInterleave,
                adaptive: _adaptiveMode,
                srEnabled: _srEnabled,
                mini: scale < 0.9,
              ),
            ),
              if (_srEnabled && _srShowCTA && _srCurrent == null)
                Positioned(
                  top: 48,
                  child: ActionChip(
                    label: Text('Review due (${_srQueue.length})'),
                    onPressed: () {
                      _maybeInjectSR(force: true);
                    },
                  ),
                ),
            if (_srCurrent != null)
              const Positioned(
                top: 48,
                child: Chip(label: Text('Review mode')),
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
                    _handleAction('push');
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
                        onTapDown: (_) => _handleAction('push'),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 100),
                          scale: _pressedAction == 'push' ? 0.95 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showActionHints ? 0.3 : 0.0,
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.black26,
                              child: Text(
                                'PUSH',
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
            if (hint.isNotEmpty && _results[spot.id] == null)
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
            // Street-specific controls removed
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
