import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_completion_entry.dart';
import 'lesson_completion_milestone_toast_service.dart';

class TheoryLessonCompletionLogger {
  TheoryLessonCompletionLogger();
  static final TheoryLessonCompletionLogger instance =
      TheoryLessonCompletionLogger();

  static const _key = 'lesson_completion_log';

  Future<void> logCompletion(String lessonId, {BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc();
    final entries = await _load(prefs);
    final exists = entries.any(
      (e) => e.lessonId == lessonId && _isSameDay(e.timestamp, now),
    );
    if (!exists) {
      entries.add(LessonCompletionEntry(lessonId: lessonId, timestamp: now));
      await _save(prefs, entries);
      if (context != null) {
        final count = await getCompletionsCountFor(DateTime.now());
        await LessonCompletionMilestoneToastService.instance
            .showIfMilestoneReached(context, count);
      }
    }
  }

  Future<List<LessonCompletionEntry>> getCompletions({DateTime? since}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _load(prefs);
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (since != null) {
      final s = since.toUtc();
      return entries.where((e) => !e.timestamp.isBefore(s)).toList();
    }
    return entries;
  }

  Future<int> getCompletionsCountFor(DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final entries = await getCompletions();
    return entries
        .where((e) => !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
        .length;
  }

  Future<List<LessonCompletionEntry>> _load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data
            .map(
              (e) => LessonCompletionEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _save(
    SharedPreferences prefs,
    List<LessonCompletionEntry> entries,
  ) async {
    await prefs.setString(
      _key,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
