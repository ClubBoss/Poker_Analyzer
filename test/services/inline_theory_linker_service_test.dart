import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_engagement_stats.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/services/inline_theory_linker_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_engagement_analytics_service.dart';
import 'package:poker_analyzer/services/theory_suggestion_engagement_tracker_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final tagSet = tags.toSet();
    final seen = <String>{};
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (l.tags.any(tagSet.contains)) {
        if (seen.add(l.id)) result.add(l);
      }
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

class _FakeAnalytics extends TheoryEngagementAnalyticsService {
  final Map<String, double> rates;
  const _FakeAnalytics(this.rates);

  @override
  Future<List<TheoryLessonEngagementStats>> getAllStats() async => [
        for (final e in rates.entries)
          TheoryLessonEngagementStats(
            lessonId: e.key,
            manualOpens: 0,
            reviewViews: 0,
            successRate: e.value,
          )
      ];
}

class _FakeTracker implements TheorySuggestionEngagementTrackerService {
  final Map<String, Map<String, int>> counts;
  _FakeTracker(this.counts);

  @override
  Future<void> lessonSuggested(String lessonId) async {}

  @override
  Future<void> lessonExpanded(String lessonId) async {}

  @override
  Future<void> lessonOpened(String lessonId) async {}

  @override
  Future<Map<String, int>> countByAction(String action) async {
    return counts[action] ?? {};
  }
}

void main() {
  test('findSuggestedLessonForSpot picks best matching lesson', () async {
    const lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'BTN Flop CBet',
        content: '',
        tags: ['btn', 'cbet', 'flop'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'BTN Probe',
        content: '',
        tags: ['btn', 'probe'],
      ),
      TheoryMiniLessonNode(
        id: 'l3',
        title: 'UTG Flop CBet',
        content: '',
        tags: ['utg', 'cbet', 'flop'],
      ),
    ];
    final service = InlineTheoryLinkerService(library: _FakeLibrary(lessons));
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(position: HeroPosition.btn),
      street: 1,
      meta: {
        'actionTags': {0: 'cbet'},
      },
    );
    final lesson = await service.findSuggestedLessonForSpot(spot);
    expect(lesson?.id, 'l1');
  });

  test('findSuggestedLessonForSpot uses engagement score tie breaker',
      () async {
    const lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'BTN Flop CBet A',
        content: '',
        tags: ['btn', 'cbet', 'flop'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'BTN Flop CBet B',
        content: '',
        tags: ['btn', 'cbet', 'flop'],
      ),
    ];
    final service = InlineTheoryLinkerService(
      library: _FakeLibrary(lessons),
      tracker: _FakeTracker({
        'suggested': {'l1': 1, 'l2': 3},
        'expanded': {'l1': 1},
        'opened': {'l2': 2},
      }),
    );
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(position: HeroPosition.btn),
      street: 1,
      meta: {
        'actionTags': {0: 'cbet'},
      },
    );
    final lesson = await service.findSuggestedLessonForSpot(spot);
    expect(lesson?.id, 'l2');
  });
  test('getLinkedLessonIdsForSpot ranks by overlap then success', () async {
    const lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['cbet', 'turn'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['cbet'],
      ),
      TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['turn'],
      ),
      TheoryMiniLessonNode(
        id: 'l4',
        title: 'D',
        content: '',
        tags: ['probe'],
      ),
    ];

    final service = InlineTheoryLinkerService(
      library: _FakeLibrary(lessons),
      analytics: const _FakeAnalytics({
        'l1': 0.9,
        'l2': 0.8,
        'l3': 0.95,
        'l4': 0.7,
      }),
    );

    final spot =
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet', 'turn']);

    final result = await service.getLinkedLessonIdsForSpot(spot);
    expect(result, ['l1', 'l3', 'l2']);
  });

  test('injectInlineLessons matches by tags and street', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'Turn CBet',
        content: '',
        tags: ['cbet', 'turn'],
        targetStreet: 'turn',
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Flop CBet',
        content: '',
        tags: ['cbet'],
        targetStreet: 'flop',
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'Flop Probe',
        content: '',
        tags: ['probe'],
        targetStreet: 'flop',
      ),
    ];
    final service = InlineTheoryLinkerService(library: _FakeLibrary(lessons));
    final spots = [
      TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['cbet', 'turn'],
        street: 2,
      ),
      TrainingPackSpot(
        id: 's2',
        hand: HandData(),
        tags: ['cbet'],
        street: 1,
      ),
      TrainingPackSpot(
        id: 's3',
        hand: HandData(),
        tags: ['probe'],
        street: 1,
      ),
    ];

    await service.injectInlineLessons(spots);

    expect(spots[0].inlineLessonId, 'l1');
    expect(spots[1].inlineLessonId, 'l2');
    expect(spots[2].inlineLessonId, 'l3');
  });

  test('attachInlineLessonsToSpot filters by street and stage', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'Flop CBet',
        content: '',
        tags: ['cbet'],
        targetStreet: 'flop',
        stage: 'basic',
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Turn CBet',
        content: '',
        tags: ['cbet', 'turn'],
        targetStreet: 'turn',
        stage: 'basic',
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'Flop Probe',
        content: '',
        tags: ['probe'],
        targetStreet: 'flop',
        stage: 'basic',
      ),
    ];
    final service = InlineTheoryLinkerService(library: _FakeLibrary(lessons));
    final spot = TrainingSpot(
      playerCards: [<CardModel>[], <CardModel>[]],
      boardCards: [
        CardModel(rank: 'A', suit: 'h'),
        CardModel(rank: 'K', suit: 'd'),
        CardModel(rank: 'Q', suit: 'c'),
      ],
      actions: <ActionEntry>[],
      heroIndex: 0,
      numberOfPlayers: 2,
      playerTypes: const [PlayerType.unknown, PlayerType.unknown],
      positions: const ['UTG', 'BB'],
      stacks: const [100, 100],
      tags: ['cbet'],
      category: 'basic',
      anteBb: 0,
      createdAt: DateTime(2024),
    );

    await service.attachInlineLessonsToSpot(spot);
    expect(spot.inlineLessons, ['l1']);
  });
}
