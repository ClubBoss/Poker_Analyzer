import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/hand_utils.dart';
import '../helpers/hand_type_utils.dart';
import '../helpers/training_pack_storage.dart';
import '../screens/training_session_summary_screen.dart';
import '../screens/pack_review_summary_screen.dart';
import '../models/session_task_result.dart';
import '../models/training_pack.dart';
import 'mistake_review_pack_service.dart';
import 'smart_review_service.dart';
import 'training_progress_logger.dart';
import 'learning_path_progress_service.dart';
import 'cloud_training_history_service.dart';
import 'learning_path_personalization_service.dart';
import 'xp_tracker_service.dart';
import 'tag_goal_tracker_service.dart';
import 'xp_reward_engine.dart';
import 'streak_reward_engine.dart';
import '../models/result_entry.dart';
import '../models/evaluation_result.dart';
import 'streak_tracker_service.dart';
import 'training_streak_tracker_service.dart';
import 'daily_streak_tracker_service.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_session.dart';
import '../models/v2/training_action.dart';
import '../models/v2/focus_goal.dart';
import '../models/category_progress.dart';
import 'recap_opportunity_detector.dart';
import 'daily_reminder_scheduler.dart';
import 'training_reminder_push_service.dart';
import 'tag_mastery_service.dart';
import 'session_log_service.dart';
import 'smart_spot_injector.dart';
import 'gift_drop_service.dart';
import 'session_streak_tracker_service.dart';
import 'smart_recap_banner_controller.dart';
import 'training_progress_tracker_service.dart';
import 'training_progress_logger.dart';
import '../app_bootstrap.dart';
import 'training_session_context_service.dart';
import 'training_session_fingerprint_logger_service.dart';

class TrainingSessionService extends ChangeNotifier {
  Box<dynamic>? _box;
  Box<dynamic>? _activeBox;
  static const _indexPrefix = 'ts_idx_';
  static const _tsPrefix = 'ts_ts_';
  static const _previewKey = 'lib_preview_completed';
  TrainingSession? _session;
  TrainingPackTemplate? _template;
  List<TrainingPackSpot> _spots = [];
  final List<TrainingAction> _actions = [];
  Timer? _timer;
  bool _paused = false;
  DateTime? _resumedAt;
  Duration _accumulated = Duration.zero;
  final List<FocusGoal> _focusHandTypes = [];
  final Map<String, int> _handGoalTotal = {};
  final Map<String, int> _handGoalCount = {};
  double _preEvPct = 0;
  double _preIcmPct = 0;
  final Map<String, CategoryProgress> _categoryStats = {};
  double _evAverageAll = 0;
  double _icmAverageAll = 0;
  final List<String> _sessionTags = [];

  double get preEvPct => _preEvPct;
  double get preIcmPct => _preIcmPct;
  double get evAverageAll => _evAverageAll;
  double get icmAverageAll => _icmAverageAll;

  bool get isPaused => _paused;
  List<FocusGoal> get focusHandTypes => List.unmodifiable(_focusHandTypes);
  Map<String, int> get handGoalTotal => Map.unmodifiable(_handGoalTotal);
  Map<String, int> get handGoalCount => Map.unmodifiable(_handGoalCount);
  Map<String, CategoryProgress> getCategoryStats() =>
      Map.unmodifiable(_categoryStats);
  List<String> get sessionTags => List.unmodifiable(_sessionTags);

  TrainingSession? get currentSession => _session;
  bool get isCompleted => _session?.completedAt != null;

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => notifyListeners());
  }

  TrainingSession? get session => _session;
  Duration get elapsedTime {
    if (_session == null) return Duration.zero;
    var d = _accumulated;
    if (!_paused && _resumedAt != null) {
      d += (_session!.completedAt ?? DateTime.now()).difference(_resumedAt!);
    }
    return d;
  }

  TrainingPackSpot? get currentSpot =>
      _session != null && _session!.index < _spots.length
      ? _spots[_session!.index]
      : null;

  Map<String, bool> get results => _session?.results ?? {};
  int get correctCount => results.values.where((e) => e).length;
  int get totalCount => results.length;
  double get evAverage {
    double sum = 0;
    int count = 0;
    for (final id in results.keys) {
      final s = _spots.firstWhere(
        (e) => e.id == id,
        orElse: () => TrainingPackSpot(id: ''),
      );
      final ev = s.heroEv;
      if (ev != null) {
        sum += ev;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  double get icmAverage {
    double sum = 0;
    int count = 0;
    for (final id in results.keys) {
      final s = _spots.firstWhere(
        (e) => e.id == id,
        orElse: () => TrainingPackSpot(id: ''),
      );
      final icm = s.heroIcmEv;
      if (icm != null) {
        sum += icm;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  List<TrainingAction> get actionLog => List.unmodifiable(_actions);
  List<TrainingAction> get completedAttempts => List.unmodifiable(_actions);
  List<TrainingPackSpot> get spots => List.unmodifiable(_spots);
  TrainingPackTemplate? get template => _template;

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
    if (!Hive.isBoxOpen('active_session')) {
      _activeBox = await Hive.openBox('active_session');
    } else {
      _activeBox = Hive.box('active_session');
    }
  }

  Future<void> load() async {
    await _openBox();
    _actions.clear();
    final raw = _activeBox!.get('session');
    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final s = data['session'];
      final spots = data['spots'];
      final actions = data['actions'];
      if (s is Map) {
        final session = TrainingSession.fromJson(Map<String, dynamic>.from(s));
        if (session.completedAt == null) {
          _session = session;
          try {
            final templates = await TrainingPackStorage.load();
            _template = templates.firstWhere(
              (t) => t.id == session.templateId,
              orElse: () => TrainingPackTemplate(id: '', name: ''),
            );
            if (_template!.id.isEmpty) _template = null;
          } catch (_) {
            _template = null;
          }
          _paused = false;
          _accumulated = Duration.zero;
          _resumedAt = DateTime.now();
          _startTicker();
          _spots = [
            for (final e in (spots as List? ?? []))
              TrainingPackSpot.fromJson(Map<String, dynamic>.from(e)),
          ];
          if (_spots.isNotEmpty) {
            final evs = _spots
                .map((e) => e.heroEv)
                .whereType<double>()
                .toList();
            if (evs.isNotEmpty) {
              _evAverageAll = evs.reduce((a, b) => a + b) / evs.length;
            }
            final icms = _spots
                .map((e) => e.heroIcmEv)
                .whereType<double>()
                .toList();
            if (icms.isNotEmpty) {
              _icmAverageAll = icms.reduce((a, b) => a + b) / icms.length;
            }
          }
          _focusHandTypes
            ..clear()
            ..addAll([
              for (final t in (data['focusHandTypes'] as List? ?? []))
                FocusGoal.fromJson(t),
            ]);
          _sessionTags
            ..clear()
            ..addAll([
              for (final t in (data['tags'] as List? ?? [])) t.toString(),
            ]);
          _preEvPct = (data['preEvPct'] as num?)?.toDouble() ?? 0;
          _preIcmPct = (data['preIcmPct'] as num?)?.toDouble() ?? 0;
          _evAverageAll = (data['evAverageAll'] as num?)?.toDouble() ?? 0;
          _icmAverageAll = (data['icmAverageAll'] as num?)?.toDouble() ?? 0;
          final totalRaw = data['handGoalTotal'];
          if (totalRaw is Map) {
            _handGoalTotal
              ..clear()
              ..addAll(
                totalRaw.map(
                  (k, v) => MapEntry(k as String, (v as num).toInt()),
                ),
              );
          } else if (totalRaw is int && _focusHandTypes.isNotEmpty) {
            _handGoalTotal[_focusHandTypes.first.label] = totalRaw;
          }
          final countRaw = data['handGoalProgress'];
          if (countRaw is Map) {
            _handGoalCount
              ..clear()
              ..addAll(
                countRaw.map(
                  (k, v) => MapEntry(k as String, (v as num).toInt()),
                ),
              );
          } else if (countRaw is int && _focusHandTypes.isNotEmpty) {
            _handGoalCount[_focusHandTypes.first.label] = countRaw;
          }
          final catRaw = data['categoryStats'];
          if (catRaw is Map) {
            _categoryStats
              ..clear()
              ..addAll(
                catRaw.map(
                  (k, v) => MapEntry(
                    k as String,
                    CategoryProgress.fromJson(
                      Map<String, dynamic>.from(v as Map),
                    ),
                  ),
                ),
              );
          }
          if (_focusHandTypes.isNotEmpty && _handGoalTotal.isEmpty) {
            for (final g in _focusHandTypes) {
              _handGoalTotal[g.label] = _spots
                  .where((s) => _matchHandTypeLabel(s, g.label))
                  .length;
            }
          }
          if (_focusHandTypes.isNotEmpty && _handGoalCount.isEmpty) {
            for (final id in _session!.results.keys) {
              final s = _spots.firstWhere(
                (e) => e.id == id,
                orElse: () => TrainingPackSpot(id: ''),
              );
              if (s.id.isEmpty) continue;
              for (final g in _focusHandTypes) {
                if (_matchHandTypeLabel(s, g.label)) {
                  _handGoalCount[g.label] = (_handGoalCount[g.label] ?? 0) + 1;
                }
              }
            }
          }
          _actions
            ..clear()
            ..addAll([
              for (final a in (actions as List? ?? []))
                TrainingAction.fromJson(Map<String, dynamic>.from(a)),
            ]);
        } else {
          _activeBox!.delete('session');
        }
      }
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _timer?.cancel();
    _session = null;
    _template = null;
    _spots.clear();
    _actions.clear();
    _focusHandTypes.clear();
    _sessionTags.clear();
    _handGoalTotal.clear();
    _handGoalCount.clear();
    _categoryStats.clear();
    _evAverageAll = 0;
    _icmAverageAll = 0;
    if (_activeBox != null) await _activeBox!.delete('session');
    unawaited(_clearIndex());
    notifyListeners();
  }

  void _saveActive() {
    if (_session == null || _activeBox == null || _session!.authorPreview) {
      return;
    }
    if (_session!.completedAt != null) {
      _activeBox!.delete('session');
    } else {
      _activeBox!.put('session', {
        'session': _session!.toJson(),
        'spots': [for (final s in _spots) s.toJson()],
        'actions': [for (final a in _actions) a.toJson()],
        if (_focusHandTypes.isNotEmpty)
          'focusHandTypes': [for (final g in _focusHandTypes) g.toString()],
        if (_handGoalTotal.isNotEmpty) 'handGoalTotal': _handGoalTotal,
        if (_handGoalCount.isNotEmpty) 'handGoalProgress': _handGoalCount,
        if (_categoryStats.isNotEmpty)
          'categoryStats': {
            for (final e in _categoryStats.entries) e.key: e.value.toJson(),
          },
        'preEvPct': _preEvPct,
        'preIcmPct': _preIcmPct,
        'evAverageAll': _evAverageAll,
        'icmAverageAll': _icmAverageAll,
        if (_sessionTags.isNotEmpty) 'tags': _sessionTags,
      });
    }
  }

  Future<void> _saveIndex() async {
    if (_template == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_indexPrefix${_template!.id}', _session?.index ?? 0);
    await prefs.setInt(
      '$_tsPrefix${_template!.id}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _clearIndex() async {
    if (_template == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_indexPrefix${_template!.id}');
    await prefs.remove('$_tsPrefix${_template!.id}');
  }

  void pause() {
    if (_paused) return;
    if (_resumedAt != null) {
      _accumulated += DateTime.now().difference(_resumedAt!);
      _resumedAt = null;
    }
    _paused = true;
    _timer?.cancel();
    _saveActive();
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _resumedAt = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  Future<void> startSession(
    TrainingPackTemplate template, {
    bool persist = true,
    int startIndex = 0,
    List<String>? sessionTags,
    String source = 'manual',
  }) async {
    if (persist) await _openBox();
    unawaited(DailyReminderScheduler.instance.cancelAll());
    unawaited(TrainingReminderPushService.instance.cancelAll());
    if (template.tags.contains('customPath')) {
      unawaited(LearningPathProgressService.instance.markCustomPathStarted());
    }
    AppBootstrap.registry.get<TrainingSessionContextService>().start(
      packId: template.id,
      trainingType: 'standard',
      includedTags: [...template.tags, ...?sessionTags],
      source: source,
    );
    _template = template;
    _sessionTags
      ..clear()
      ..addAll(sessionTags ?? []);
    unawaited(TrainingProgressLogger.startSession(template.id));
    final total = template.totalWeight;
    _preEvPct = total == 0 ? 0 : template.evCovered * 100 / total;
    _preIcmPct = total == 0 ? 0 : template.icmCovered * 100 / total;
    _spots = List<TrainingPackSpot>.from(template.spots);

    if (SmartSpotInjector.instance.enabled) {
      final logs = SessionLogService(sessions: this);
      final mastery = TagMasteryService(logs: logs);
      _spots = await SmartSpotInjector.instance.injectWeaknessSpots(
        originalSpots: _spots,
        logs: logs,
        mastery: mastery,
      );
      logs.dispose();
    }
    _evAverageAll = 0;
    _icmAverageAll = 0;
    if (_spots.isNotEmpty) {
      final evs = _spots.map((e) => e.heroEv).whereType<double>().toList();
      if (evs.isNotEmpty) {
        _evAverageAll = evs.reduce((a, b) => a + b) / evs.length;
      }
      final icms = _spots.map((e) => e.heroIcmEv).whereType<double>().toList();
      if (icms.isNotEmpty) {
        _icmAverageAll = icms.reduce((a, b) => a + b) / icms.length;
      }
    }
    _actions.clear();
    _focusHandTypes
      ..clear()
      ..addAll(template.focusHandTypes);
    _handGoalTotal.clear();
    _handGoalCount.clear();
    _categoryStats.clear();
    for (final g in _focusHandTypes) {
      _handGoalTotal[g.label] = _spots
          .where((s) => _matchHandTypeLabel(s, g.label))
          .length;
      _handGoalCount[g.label] = 0;
    }
    int savedIndex = startIndex;
    if (persist && startIndex == 0) {
      final prefs = await SharedPreferences.getInstance();
      savedIndex = prefs.getInt('$_indexPrefix${template.id}') ?? 0;
    }
    _session = TrainingSession.fromTemplate(template, authorPreview: !persist);
    if (savedIndex > 0 && savedIndex < _spots.length) {
      _session!.index = savedIndex;
    }
    _paused = false;
    _accumulated = Duration.zero;
    _resumedAt = DateTime.now();
    _startTicker();
    if (persist && _box != null) {
      await _box!.put(_session!.id, _session!.toJson());
      _saveActive();
      unawaited(_saveIndex());
    }
    notifyListeners();
  }

  Future<TrainingSession> startFromTemplate(
    TrainingPackTemplate template,
  ) async {
    await startSession(template, persist: false);
    return _session!;
  }

  Future<TrainingSession> startFromMistakes() async {
    final ids = results.keys.where((k) => results[k] == false).toSet();
    final spots = _spots.where((s) => ids.contains(s.id)).toList();
    final tpl = _template!.copyWith(
      id: const Uuid().v4(),
      name: 'Retry mistakes',
      spots: spots,
    );
    return startFromTemplate(tpl);
  }

  Future<TrainingSession?> startFromPastMistakes(
    TrainingPackTemplate template,
  ) async {
    await _openBox();
    final ids = <String>{};
    for (final v in _box!.values.whereType<Map>()) {
      try {
        final s = TrainingSession.fromJson(Map<String, dynamic>.from(v));
        if (s.templateId == template.id) {
          ids.addAll(
            s.results.entries.where((e) => e.value == false).map((e) => e.key),
          );
        }
      } catch (_) {}
    }
    final spots = [
      for (final s in template.spots)
        if (ids.contains(s.id)) TrainingPackSpot.fromJson(s.toJson()),
    ];
    if (spots.isEmpty) return null;
    final tpl = template.copyWith(name: 'Review Mistakes', spots: spots);
    await startSession(tpl, persist: false);
    return _session;
  }

  Future<void> complete(
    BuildContext context, {
    WidgetBuilder? resultBuilder,
  }) async {
    if (_session == null || _template == null) return;
    if (_template!.meta['samplePreview'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_previewKey) ?? [];
      if (!list.contains(_template!.id)) {
        list.add(_template!.id);
        await prefs.setStringList(_previewKey, list);
      }
    }
    final ids = [
      for (final e in _session!.results.entries)
        if (!e.value) e.key,
    ];
    if (ids.isNotEmpty) {
      final tpl = _template!.copyWith(
        id: const Uuid().v4(),
        name: 'Review mistakes',
        spots: [
          for (final s in _template!.spots)
            if (ids.contains(s.id)) s,
        ],
      );
      MistakeReviewPackService.setLatestTemplate(tpl);
      await context.read<MistakeReviewPackService>().addPack(
        ids,
        templateId: _template!.id,
      );
    }
    unawaited(
      context.read<CloudTrainingHistoryService>().saveSession(_buildResults()),
    );

    // Calculate XP reward with personalization boost
    final xpService = context.read<XPTrackerService>();
    final skills = LearningPathPersonalizationService.instance.getTagSkillMap();
    double multiplier = 1.0;
    for (final tag in _template!.tags) {
      final skill = skills[tag.toLowerCase()] ?? 0.5;
      final m = _xpMultiplier(skill);
      if (m > multiplier) multiplier = m;
    }
    int xp = XPTrackerService.targetXp;
    final bonusCap = (xp * 0.5).round();
    int bonus = ((xp * multiplier) - xp).round();
    if (bonus > bonusCap) bonus = bonusCap;
    xp += bonus;

    final streakMultiplier = await xpService.getStreakMultiplier();
    xp = (xp * streakMultiplier).round();

    final Map<String, int> tagXp = {};
    for (final tag in _template!.tags) {
      final skill = skills[tag.toLowerCase()] ?? 0.5;
      final txp = XPTrackerService.targetXp * _xpMultiplier(skill);
      tagXp[tag.toLowerCase()] = txp.round();
    }
    await xpService.addPerTagXP(tagXp, source: 'training');
    final streak = await StreakTrackerService.instance.getCurrentStreak();
    await xpService.add(xp: xp, source: 'training', streak: streak);
    unawaited(XPRewardEngine.instance.addXp(25));
    for (final tag in _template!.tags) {
      unawaited(TagGoalTrackerService.instance.logTraining(tag));
    }
    unawaited(
      TrainingStreakTrackerService.instance.markTrainingCompletedToday(),
    );
    unawaited(DailyStreakTrackerService.instance.markCompletedToday());
    unawaited(StreakRewardEngine.instance.checkAndTriggerRewards());
    unawaited(
      context.read<GiftDropService>().checkAndDropGift(context: context),
    );
    unawaited(SessionStreakTrackerService.instance.markCompletedToday());
    unawaited(SessionStreakTrackerService.instance.checkAndTriggerRewards());
    unawaited(_clearIndex());
    final mastery = context.read<TagMasteryService>();
    final deltas = await mastery.updateWithSession(
      template: _template!,
      results: _session!.results,
      dryRun: true,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            resultBuilder ??
            (_) => TrainingSessionSummaryScreen(
              session: _session!,
              template: _template!,
              preEvPct: _preEvPct,
              preIcmPct: _preIcmPct,
              xpEarned: xp,
              xpMultiplier: multiplier,
              streakMultiplier: streakMultiplier,
              tagDeltas: deltas,
            ),
      ),
    );
  }

  Future<void> submitResult(
    String spotId,
    String action,
    bool isCorrect,
  ) async {
    if (_session == null) return;
    final first = !_session!.results.containsKey(spotId);
    _session!.results[spotId] = isCorrect;
    _actions.add(
      TrainingAction(
        spotId: spotId,
        chosenAction: action,
        isCorrect: isCorrect,
      ),
    );
    final spot = _spots.firstWhere(
      (e) => e.id == spotId,
      orElse: () => TrainingPackSpot(id: ''),
    );
    if (spot.id.isNotEmpty) {
      if (first && !isCorrect) {
        unawaited(SmartReviewService.instance.recordMistake(spot));
      }
      for (final t in spot.tags.where((t) => t.startsWith('cat:'))) {
        final cat = t.substring(4);
        final stat = _categoryStats.putIfAbsent(cat, () => CategoryProgress());
        if (first) stat.played += 1;
        if (first && isCorrect) stat.correct += 1;
        final ev = spot.heroEv;
        if (ev != null && first) {
          if (isCorrect) {
            stat.evSaved += ev.abs();
          } else {
            stat.evLost += ev.abs();
          }
        }
      }
    }
    if (first && _template != null) {
      unawaited(
        TrainingProgressTrackerService.instance.recordSpotCompleted(
          _template!.id,
          spotId,
        ),
      );
    }
    if (first && _focusHandTypes.isNotEmpty) {
      if (spot.id.isNotEmpty) {
        for (final g in _focusHandTypes) {
          if (_matchHandTypeLabel(spot, g.label)) {
            _handGoalCount[g.label] = (_handGoalCount[g.label] ?? 0) + 1;
          }
        }
      }
    }
    if (_box != null) await _box!.put(_session!.id, _session!.toJson());
    _saveActive();
    unawaited(_saveIndex());
    notifyListeners();
  }

  TrainingPackSpot? nextSpot() {
    if (_session == null) return null;
    _session!.index += 1;
    if (_session!.index >= _spots.length) {
      _session!.completedAt = DateTime.now();
      if (_template?.tags.contains('customPath') ?? false) {
        unawaited(
          LearningPathProgressService.instance.markCustomPathCompleted(),
        );
      }
      if (!_paused && _resumedAt != null) {
        _accumulated += DateTime.now().difference(_resumedAt!);
        _resumedAt = null;
      }
      _timer?.cancel();
      final total = _session!.results.length;
      final correct = _session!.results.values.where((e) => e).length;
      final tags = <String>{...?_template?.tags, ..._sessionTags};
      final fp = TrainingSessionFingerprint(
        packId: _template?.id ?? '',
        tags: tags.toList(),
        completedAt: _session!.completedAt!,
        totalSpots: total,
        correct: correct,
        incorrect: total - correct,
      );
      unawaited(TrainingSessionFingerprintLoggerService().logSession(fp));
      unawaited(RecapOpportunityDetector.instance.notifyDrillCompleted());
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        unawaited(
          ctx.read<SmartRecapBannerController>().triggerBannerIfNeeded(),
        );
        if (_template != null) {
          final totalHands = _spots.length;
          final totalSpots = _template!.totalWeight;
          final evAfter = totalSpots == 0
              ? 0.0
              : _template!.evCovered * 100 / totalSpots;
          unawaited(
            TrainingProgressLogger.finishSession(
              _template!.id,
              totalHands,
              evPercent: evAfter,
              requiredAccuracy: _template!.requiredAccuracy,
              minHands: _template!.minHands,
            ),
          );
          final correctHands = _session!.results.values.where((e) => e).length;
          final tasks = [
            for (final a in _actions)
              (() {
                final spot = _spots.firstWhere(
                  (s) => s.id == a.spotId,
                  orElse: () => TrainingPackSpot(id: ''),
                );
                return SessionTaskResult(
                  question: spot.title.isNotEmpty ? spot.title : spot.id,
                  selectedAnswer: a.chosenAction,
                  correctAnswer: _expectedAction(spot) ?? '',
                  correct: a.isCorrect,
                );
              })(),
          ];
          final result = TrainingSessionResult(
            date: DateTime.now(),
            total: totalHands,
            correct: correctHands,
            tasks: tasks,
          );
          unawaited(
            complete(
              ctx,
              resultBuilder: (_) => PackReviewSummaryScreen(
                template: _template!,
                result: result,
                elapsed: elapsedTime,
              ),
            ),
          );
        }
      }
    }
    if (_box != null) _box!.put(_session!.id, _session!.toJson());
    _saveActive();
    if (_session!.completedAt == null) {
      unawaited(_saveIndex());
    }
    notifyListeners();
    return currentSpot;
  }

  TrainingPackSpot? prevSpot() {
    if (_session == null) return null;
    if (_session!.index > 0) {
      _session!.index -= 1;
      if (_box != null) _box!.put(_session!.id, _session!.toJson());
      _saveActive();
      unawaited(_saveIndex());
      notifyListeners();
    }
    return currentSpot;
  }

  Future<void> updateSpot(TrainingPackSpot spot) async {
    final index = _spots.indexWhere((s) => s.id == spot.id);
    if (index == -1) return;
    _spots[index] = spot;
    if (_session != null) {
      if (_box != null) await _box!.put(_session!.id, _session!.toJson());
      _saveActive();
    }
    notifyListeners();
  }

  bool _matchHandTypeLabel(TrainingPackSpot spot, String label) {
    final code = handCode(spot.hand.heroCards);
    if (code == null) return false;
    return matchHandTypeLabel(label, code);
  }

  bool _matchHandType(TrainingPackSpot spot) {
    for (final g in _focusHandTypes) {
      if (_matchHandTypeLabel(spot, g.label)) return true;
    }
    return false;
  }

  String? _expectedAction(TrainingPackSpot spot) {
    final acts = spot.hand.actions.isNotEmpty ? spot.hand.actions[0] : [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }

  double _xpMultiplier(double skill) {
    if (skill < 0.4) return 2.0;
    if (skill < 0.6) return 1.5;
    return 1.0;
  }

  List<ResultEntry> _buildResults() {
    return [
      for (final a in _actions)
        (() {
          final spot = _spots.firstWhere(
            (s) => s.id == a.spotId,
            orElse: () => TrainingPackSpot(id: ''),
          );
          if (spot.id.isEmpty) return null;
          final eval = EvaluationResult(
            correct: a.isCorrect,
            expectedAction: _expectedAction(spot) ?? '',
            userEquity: 0,
            expectedEquity: 0,
          );
          return ResultEntry(
            name: spot.title.isNotEmpty ? spot.title : spot.id,
            userAction: a.chosenAction,
            evaluation: eval,
          );
        })(),
    ].whereType<ResultEntry>().toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
