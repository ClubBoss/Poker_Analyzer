import '../models/inline_theory_linked_text.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/spot_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_spot.dart';
import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';
import 'theory_engagement_analytics_service.dart';
import 'theory_suggestion_engagement_tracker_service.dart';

class InlineTheoryLinkerService {
  InlineTheoryLinkerService({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
    TheoryEngagementAnalyticsService? analytics,
    TheorySuggestionEngagementTrackerService? tracker,
  }) : _library = library ?? MiniLessonLibraryService.instance,
       _navigator = navigator ?? TheoryMiniLessonNavigator.instance,
       _analytics = analytics ?? const TheoryEngagementAnalyticsService(),
       _tracker = tracker ?? TheorySuggestionEngagementTrackerService.instance;

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;
  final TheoryEngagementAnalyticsService _analytics;
  final TheorySuggestionEngagementTrackerService _tracker;

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
          '\\b${RegExp.escape(tag)}\\b',
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
        final regex = RegExp('\\b${RegExp.escape(k)}\\b', caseSensitive: false);
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

  /// Computes engagement score for the lesson with [lessonId].
  ///
  /// The score is a weighted sum of suggestion, expansion and open counts.
  Future<double> getEngagementScore(String lessonId) async {
    final suggested = await _tracker.countByAction('suggested');
    final expanded = await _tracker.countByAction('expanded');
    final opened = await _tracker.countByAction('opened');
    final s = suggested[lessonId] ?? 0;
    final e = expanded[lessonId] ?? 0;
    final o = opened[lessonId] ?? 0;
    return s * 0.2 + e * 0.3 + o * 0.5;
  }

  /// Finds the most relevant [TheoryMiniLessonNode] for the given [spot].
  ///
  /// The match score prioritizes:
  /// - exact position and street matches
  /// - presence of keywords from [actionTags]
  Future<TheoryMiniLessonNode?> findSuggestedLessonForSpot(
    TrainingPackSpot spot,
  ) async {
    await _library.loadAll();

    final position = spot.hand.position.name.toLowerCase();
    final street = _streetName(spot.street).toLowerCase();

    final actionKeywords = <String>{};
    final rawActions = spot.meta['actionTags'];
    if (rawActions is Map) {
      for (final v in rawActions.values) {
        if (v is String) {
          final parts = v.toLowerCase().split(RegExp(r'[^a-z0-9]+'))
            ..removeWhere((e) => e.isEmpty);
          actionKeywords.addAll(parts);
        }
      }
    } else if (rawActions is List) {
      for (final v in rawActions) {
        if (v is String) {
          final parts = v.toLowerCase().split(RegExp(r'[^a-z0-9]+'))
            ..removeWhere((e) => e.isEmpty);
          actionKeywords.addAll(parts);
        }
      }
    }

    TheoryMiniLessonNode? best;
    int bestScore = 0;
    final top = <TheoryMiniLessonNode>[];

    for (final lesson in _library.all) {
      final tags = lesson.tags.map((t) => t.toLowerCase()).toSet();
      final title = lesson.title.toLowerCase();

      var score = 0;
      if (position.isNotEmpty &&
          (tags.contains(position) || title.contains(position))) {
        score += 4;
      }
      if (street.isNotEmpty &&
          ((lesson.targetStreet?.toLowerCase() == street) ||
              tags.contains(street) ||
              title.contains(street))) {
        score += 4;
      }
      for (final k in actionKeywords) {
        if (tags.contains(k) || title.contains(k)) {
          score += 1;
        }
      }

      if (best == null || score > bestScore) {
        bestScore = score;
        best = lesson;
        top
          ..clear()
          ..add(lesson);
      } else if (score == bestScore && bestScore > 0) {
        top.add(lesson);
      }
    }

    if (best == null) return null;
    if (top.length == 1) return best;

    final engagement = <TheoryMiniLessonNode, double>{};
    for (final l in top) {
      engagement[l] = await getEngagementScore(l.id);
    }
    final hasNonZero = engagement.values.any((v) => v > 0);
    if (!hasNonZero) return best;

    top.sort((a, b) => engagement[b]!.compareTo(engagement[a]!));
    return top.first;
  }

  /// Returns up to 3 lesson ids that best match [spot] based on tag overlap
  /// and success rate analytics.
  Future<List<String>> getLinkedLessonIdsForSpot(SpotModel spot) async {
    await _library.loadAll();
    final spotTags = spot.tags.map((t) => t.trim().toLowerCase()).toSet()
      ..removeWhere((t) => t.isEmpty);
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

  /// Populates [spot.inlineLessons] with up to [maxCount] lesson ids matched
  /// by tags, target street and stage.
  Future<void> attachInlineLessonsToSpot(
    TrainingSpot spot, {
    int maxCount = 3,
  }) async {
    await _library.loadAll();
    final spotTags = spot.tags.map((t) => t.trim().toLowerCase()).toSet()
      ..removeWhere((t) => t.isEmpty);
    if (spotTags.isEmpty) return;
    final lessons = _library.findByTags(spotTags.toList());
    if (lessons.isEmpty) return;
    final street = _spotStreetName(spot).toLowerCase();
    final stage = spot.category?.toLowerCase();

    final filtered = <TheoryMiniLessonNode>[];
    for (final lesson in lessons) {
      if (lesson.targetStreet != null &&
          lesson.targetStreet!.isNotEmpty &&
          lesson.targetStreet!.toLowerCase() != street) {
        continue;
      }
      if (lesson.stage != null &&
          lesson.stage!.isNotEmpty &&
          stage != null &&
          lesson.stage!.toLowerCase() != stage) {
        continue;
      }
      filtered.add(lesson);
    }

    filtered.sort((a, b) {
      final tagsA = a.tags.map((t) => t.toLowerCase()).toSet();
      final tagsB = b.tags.map((t) => t.toLowerCase()).toSet();
      final overlapA = tagsA.intersection(spotTags).length;
      final overlapB = tagsB.intersection(spotTags).length;
      return overlapB - overlapA;
    });

    spot.inlineLessons
      ..clear()
      ..addAll(filtered.take(maxCount).map((l) => l.id));
  }

  String _spotStreetName(TrainingSpot spot) {
    final count = spot.boardCards.length;
    switch (count) {
      case 0:
        return 'preflop';
      case 3:
        return 'flop';
      case 4:
        return 'turn';
      case 5:
        return 'river';
      default:
        return 'preflop';
    }
  }

  /// Injects [inlineLessonId] into each [spot] based on matching tags and
  /// street. Spots that already have an [inlineLessonId] are left unchanged.
  Future<void> injectInlineLessons(List<TrainingPackSpot> spots) async {
    if (spots.isEmpty) return;
    await _library.loadAll();
    final lessons = _library.all;
    for (final spot in spots) {
      if (spot.inlineLessonId != null && spot.inlineLessonId!.isNotEmpty) {
        continue;
      }
      final spotTags = spot.tags.map((t) => t.trim().toLowerCase()).toSet()
        ..removeWhere((t) => t.isEmpty);
      if (spotTags.isEmpty) continue;
      final streetName = _streetName(spot.street).toLowerCase();

      TheoryMiniLessonNode? best;
      int bestOverlap = 0;
      for (final lesson in lessons) {
        if (lesson.tags.isEmpty) continue;
        if (lesson.targetStreet != null &&
            lesson.targetStreet!.isNotEmpty &&
            lesson.targetStreet!.toLowerCase() != streetName) {
          continue;
        }
        final overlap = lesson.tags
            .map((t) => t.toLowerCase())
            .toSet()
            .intersection(spotTags)
            .length;
        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          best = lesson;
        }
      }
      if (best != null && bestOverlap > 0) {
        spot.inlineLessonId = best.id;
      }
    }
  }

  String _streetName(int street) {
    const names = ['preflop', 'flop', 'turn', 'river'];
    if (street >= 0 && street < names.length) return names[street];
    return '';
  }
}

class _Match {
  final int start;
  final int end;
  final String tag;
  _Match(this.start, this.end, this.tag);
}
