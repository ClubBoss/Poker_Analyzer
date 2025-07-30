import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
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
  final bool debug;

  SmartRecapSuggestionEngine({
    RecapFatigueEvaluator? fatigue,
    TheoryReinforcementScheduler? scheduler,
    TheoryWeaknessRepeater? repeater,
    MiniLessonLibraryService? library,
    RecapHistoryTracker? history,
    this.debug = false,
  })  : fatigue = fatigue ?? RecapFatigueEvaluator.instance,
        scheduler = scheduler ?? TheoryReinforcementScheduler.instance,
        repeater = repeater ?? const TheoryWeaknessRepeater(),
        library = library ?? MiniLessonLibraryService.instance,
        history = history ?? RecapHistoryTracker.instance;

  static final SmartRecapSuggestionEngine instance = SmartRecapSuggestionEngine();

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

  Future<TheoryMiniLessonNode?> getBestRecapCandidate() async {
    if (await fatigue.isFatiguedGlobally()) {
      if (debug) debugPrint('recap: global fatigue');
      return null;
    }

    await library.loadAll();
    final schedule = await _loadSchedule();
    final now = DateTime.now();
    final due = schedule.entries
        .where((e) => !e.value.isAfter(now))
        .toList()
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
      final recency = last == null ? 1e6 : now.difference(last).inMinutes.toDouble();
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
        final recency = last == null ? 1e6 : now.difference(last).inMinutes.toDouble();
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

