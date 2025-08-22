import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/goal_slot_allocator.dart';
import 'package:poker_analyzer/services/mistake_tag_insights_service.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/models/xp_guided_goal.dart';
import 'package:poker_analyzer/models/mistake_insight.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeInsights extends MistakeTagInsightsService {
  final List<MistakeInsight> list;
  const _FakeInsights(this.list);
  @override
  Future<List<MistakeInsight>> buildInsights({
    bool sortByEvLoss = false,
  }) async => list;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> items;
  _FakeLibrary(List<TheoryMiniLessonNode> lessons)
    : items = {for (final l in lessons) l.id: l};

  @override
  List<TheoryMiniLessonNode> get all => items.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) => items[id];

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final res = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      res.addAll(items.values.where((e) => e.tags.contains(t)));
    }
    return res;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('assigns home slot for top weakness smart goal', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
      tags: ['overly loose push'],
    );
    final goal = XPGuidedGoal(
      id: 'l1',
      label: 'G1',
      xp: 10,
      source: 'smart',
      onComplete: () {},
    );
    final allocator = GoalSlotAllocator(
      insights: _FakeInsights([
        const MistakeInsight(
          tag: MistakeTag.overpush,
          count: 3,
          evLoss: 5,
          shortExplanation: '',
          examples: [],
        ),
      ]),
      library: _FakeLibrary([lesson]),
    );
    final res = await allocator.allocate([goal]);
    expect(res.single.slot, 'home');
  });

  test('assigns postrecap slot when tag completed recently', () async {
    await BoosterPathHistoryService.instance.markCompleted(
      'l2',
      'btn overfold',
    );
    final lesson = const TheoryMiniLessonNode(
      id: 'l2',
      title: 'B',
      content: '',
      tags: ['btn overfold'],
    );
    final goal = XPGuidedGoal(
      id: 'l2',
      label: 'G2',
      xp: 10,
      source: 'theory',
      onComplete: () {},
    );
    final allocator = GoalSlotAllocator(
      insights: const _FakeInsights([]),
      library: _FakeLibrary([lesson]),
    );
    final res = await allocator.allocate([goal]);
    expect(res.single.slot, 'postrecap');
  });

  test('defaults to theory slot', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l3',
      title: 'C',
      content: '',
      tags: ['other'],
    );
    final goal = XPGuidedGoal(
      id: 'l3',
      label: 'G3',
      xp: 5,
      source: 'manual',
      onComplete: () {},
    );
    final allocator = GoalSlotAllocator(
      insights: const _FakeInsights([]),
      library: _FakeLibrary([lesson]),
    );
    final res = await allocator.allocate([goal]);
    expect(res.single.slot, 'theory');
  });
}
