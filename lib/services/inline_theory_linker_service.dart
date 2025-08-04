import 'package:flutter/material.dart';

import '../models/inline_theory_linked_text.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/spot_model.dart';
import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';
import 'theory_engagement_analytics_service.dart';

class InlineTheoryLinkerService {
  InlineTheoryLinkerService({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
    TheoryEngagementAnalyticsService? analytics,
  }) : _library = library ?? MiniLessonLibraryService.instance,
       _navigator = navigator ?? TheoryMiniLessonNavigator.instance,
       _analytics = analytics ?? const TheoryEngagementAnalyticsService();

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;
  final TheoryEngagementAnalyticsService _analytics;

  /// Parses [description] and converts matching keywords to inline links.
  ///
  /// Only lessons sharing at least one of [contextTags] are considered.
  InlineTheoryLinkedText link(
    String description, {
    List<String> contextTags = const [],
  }) {
    final candidates = _library.all.where((l) {
      if (contextTags.isEmpty) return true;
      return l.tags.any((t) => contextTags.contains(t));
    }).toList();

    final matches = <_Match>[];
    for (final lesson in candidates) {
      if (lesson.tags.isEmpty) continue;
      for (final tag in lesson.tags) {
        final regex = RegExp(
          '\\b' + RegExp.escape(tag) + '\\b',
          caseSensitive: false,
        );
        for (final m in regex.allMatches(description)) {
          matches.add(_Match(m.start, m.end, tag));
        }
      }
      // keyword match using lesson title
      final keywords = lesson.title.split(RegExp('\\s+'));
      for (final k in keywords) {
        if (k.isEmpty) continue;
        final regex = RegExp(
          '\\b' + RegExp.escape(k) + '\\b',
          caseSensitive: false,
        );
        for (final m in regex.allMatches(description)) {
          matches.add(_Match(m.start, m.end, lesson.tags.first));
        }
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    final filtered = <_Match>[];
    int lastEnd = -1;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        filtered.add(m);
        lastEnd = m.end;
      }
    }

    final chunks = <InlineTextChunk>[];
    int index = 0;
    for (final m in filtered) {
      if (m.start > index) {
        chunks.add(
          InlineTextChunk(text: description.substring(index, m.start)),
        );
      }
      final text = description.substring(m.start, m.end);
      chunks.add(
        InlineTextChunk(
          text: text,
          onTap: () => _navigator.openLessonByTag(m.tag),
        ),
      );
      index = m.end;
    }
    if (index < description.length) {
      chunks.add(InlineTextChunk(text: description.substring(index)));
    }
    return InlineTheoryLinkedText(chunks);
  }

  /// Returns lessons related to the provided [tags].
  Future<List<TheoryMiniLessonNode>> extractRelevantLessons(
    List<String> tags,
  ) async {
    await _library.loadAll();
    return _library.findByTags(tags);
  }

  /// Returns up to 3 lesson ids that best match [spot] based on tag overlap
  /// and success rate analytics.
  Future<List<String>> getLinkedLessonIdsForSpot(SpotModel spot) async {
    await _library.loadAll();
    final spotTags =
        spot.tags.map((t) => t.trim().toLowerCase()).toSet()..removeWhere((t) => t.isEmpty);
    if (spotTags.isEmpty) return const [];

    final lessons = _library.findByTags(spotTags.toList());
    if (lessons.isEmpty) return const [];

    final stats = await _analytics.getAllStats();
    final success = <String, double>{
      for (final s in stats) s.lessonId: s.successRate,
    };

    lessons.sort((a, b) {
      final tagsA = a.tags.map((t) => t.toLowerCase()).toSet();
      final tagsB = b.tags.map((t) => t.toLowerCase()).toSet();
      final overlapA = tagsA.intersection(spotTags).length;
      final overlapB = tagsB.intersection(spotTags).length;
      if (overlapA != overlapB) return overlapB - overlapA;
      final rateA = success[a.id] ?? 0.0;
      final rateB = success[b.id] ?? 0.0;
      return rateB.compareTo(rateA);
    });

    return lessons.take(3).map((l) => l.id).toList();
  }
}

class _Match {
  final int start;
  final int end;
  final String tag;
  _Match(this.start, this.end, this.tag);
}
