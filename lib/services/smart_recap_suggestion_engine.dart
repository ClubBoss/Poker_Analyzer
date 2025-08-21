import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'recap_auto_repeat_scheduler.dart';
import 'recap_fatigue_evaluator.dart';
import 'recap_history_tracker.dart';
import 'theory_reinforcement_scheduler.dart';
import 'theory_weakness_repeater.dart';

/// Central orchestrator selecting the most appropriate recap lesson.
class SmartRecapSuggestionEngine {
  final RecapFatigueEvaluator fatigue;
  final TheoryReinforcementScheduler scheduler;
  final TheoryWeaknessRepeater repeater;
  final MiniLessonLibraryService library;
  final RecapHistoryTracker history;
  final RecapAutoRepeatScheduler repeats;
  final bool debug;

  SmartRecapSuggestionEngine({
    RecapFatigueEvaluator? fatigue,
    TheoryReinforcementScheduler? scheduler,
    TheoryWeaknessRepeater? repeater,
    MiniLessonLibraryService? library,
    RecapHistoryTracker? history,
    RecapAutoRepeatScheduler? repeats,
    this.debug = false,
  })  : fatigue = fatigue ?? RecapFatigueEvaluator.instance,
        scheduler = scheduler ?? TheoryReinforcementScheduler.instance,
        repeater = repeater ?? const TheoryWeaknessRepeater(),
        library = library ?? MiniLessonLibraryService.instance,
        history = history ?? RecapHistoryTracker.instance,
        repeats = repeats ?? RecapAutoRepeatScheduler.instance;

  static final SmartRecapSuggestionEngine instance =
      SmartRecapSuggestionEngine();

  final StreamController<TheoryMiniLessonNode> _ctrl =
      StreamController<TheoryMiniLessonNode>.broadcast();
  StreamSubscription<List<String>>? _repeatSub;
  Timer? _timer;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// Combined stream of recap lesson suggestions.
  Stream<TheoryMiniLessonNode> get nextRecap => _ctrl.stream;

  Future<Map<String, DateTime>> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_schedule');
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        final map = <String, DateTime>{};
        for (final e in data.entries) {
          if (e.value is Map) {
            final m = Map<String, dynamic>.from(e.value as Map);
            final ts = DateTime.tryParse(m['next']?.toString() ?? '');
            if (ts != null) map[e.key.toString()] = ts;
          }
        }
        return map;
      }
    } catch (_) {}
    return {};
  }

  Future<DateTime?> _lastShown(String id) async {
    final events = await history.getHistory(lessonId: id);
    return events.isEmpty ? null : events.first.timestamp;
  }

  Future<DateTime?> _lastCompleted(String id) async {
    final events = await history.getHistory(lessonId: id);
    for (final e in events) {
      if (e.eventType == 'completed') return e.timestamp;
    }
    return null;
  }

  void _emit(TheoryMiniLessonNode lesson) {
    final now = DateTime.now();
    if (now.difference(_lastEmit) < const Duration(minutes: 5)) return;
    _lastEmit = now;
    _ctrl.add(lesson);
  }

  Future<void> _handleRepeatIds(List<String> ids) async {
    final now = DateTime.now();
    for (final id in ids) {
      final lesson = library.getById(id);
      if (lesson == null) continue;
      final last = await _lastCompleted(id);
      if (last != null && now.difference(last).inDays < 3) continue;
      _emit(lesson);
    }
  }

  Future<void> start({Duration interval = const Duration(hours: 1)}) async {
    await library.loadAll();
    _repeatSub?.cancel();
    _repeatSub =
        repeats.getPendingRecapIds(interval: interval).listen(_handleRepeatIds);
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final lesson = await getBestRecapCandidate();
      if (lesson != null) _emit(lesson);
    });
    final first = await getBestRecapCandidate();
    if (first != null) _emit(first);
  }

  Future<void> dispose() async {
    await _repeatSub?.cancel();
    _timer?.cancel();
    await _ctrl.close();
  }

  Future<TheoryMiniLessonNode?> getBestRecapCandidate() async {
    if (await fatigue.isFatiguedGlobally()) {
      if (debug) debugPrint('recap: global fatigue');
      return null;
    }

    await library.loadAll();
    final schedule = await _loadSchedule();
    final now = DateTime.now();
    final due = schedule.entries.where((e) => !e.value.isAfter(now)).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final candidates = <_Entry>[];

    for (final e in due) {
      final lesson = library.getById(e.key);
      if (lesson == null) continue;
      if (await fatigue.isLessonFatigued(lesson.id)) {
        if (debug) debugPrint('recap: skip ${lesson.id} fatigued');
        continue;
      }
      final last = await _lastShown(lesson.id);
      final overdue = now.difference(e.value).inMinutes.toDouble();
      final recency =
          last == null ? 1e6 : now.difference(last).inMinutes.toDouble();
      final score = 1000 + overdue + recency;
      candidates.add(_Entry(lesson, score));
      if (debug) debugPrint('recap candidate due ${lesson.id} score $score');
    }

    if (candidates.isEmpty) {
      final weak = await repeater.recommend();
      for (final lesson in weak) {
        if (await fatigue.isLessonFatigued(lesson.id)) {
          if (debug) debugPrint('recap: skip ${lesson.id} fatigued');
          continue;
        }
        final last = await _lastShown(lesson.id);
        final recency =
            last == null ? 1e6 : now.difference(last).inMinutes.toDouble();
        final score = recency;
        candidates.add(_Entry(lesson, score));
        if (debug) debugPrint('recap candidate weak ${lesson.id} score $score');
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final chosen = candidates.first.lesson;
    if (debug) debugPrint('recap chosen ${chosen.id}');
    return chosen;
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Entry(this.lesson, this.score);
}
