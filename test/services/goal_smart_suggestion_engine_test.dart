import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/mistake_insight.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/booster_lesson_status.dart';
import 'package:poker_analyzer/services/goal_smart_suggestion_engine.dart';
import 'package:poker_analyzer/services/booster_lesson_status_service.dart';
import 'package:poker_analyzer/services/inbox_booster_tuner_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mistake_tag_insights_service.dart';

class _FakeInsights extends MistakeTagInsightsService {
  final List<MistakeInsight> list;
  const _FakeInsights(this.list);
  @override
  Future<List<MistakeInsight>> buildInsights({
    bool sortByEvLoss = false,
  }) async => list;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
  @override
  List<TheoryMiniLessonNode> get all => items;
  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final res = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      res.addAll(items.where((e) => e.tags.contains(t)));
    }
    return res;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

class _FakeStatus extends BoosterLessonStatusService {
  final Map<String, BoosterLessonStatus> map;
  _FakeStatus(this.map)
    : super(
        tracker: InboxBoosterTrackerService.instance,
        history: BoosterPathHistoryService.instance,
      );
  @override
  Future<BoosterLessonStatus> getStatus(TheoryMiniLessonNode lesson) async =>
      map[lesson.id] ?? BoosterLessonStatus.newLesson;
}

class _FakeTuner extends InboxBoosterTunerService {
  final Map<String, double> scores;
  _FakeTuner(this.scores)
    : super(
        tracker: InboxBoosterTrackerService.instance,
        library: MiniLessonLibraryService.instance,
      );
  @override
  Future<Map<String, double>> computeTagBoostScores({
    DateTime? now,
    int recencyDays = 3,
  }) async => scores;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateGoals returns filtered smart goals', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['push'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['call'],
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['fold'],
      ),
    ];
    final insights = [
      MistakeInsight(
        tag: MistakeTag.overpush,
        count: 3,
        evLoss: 10,
        shortExplanation: '',
        examples: const [],
      ),
      MistakeInsight(
        tag: MistakeTag.looseCallBb,
        count: 2,
        evLoss: 5,
        shortExplanation: '',
        examples: const [],
      ),
      MistakeInsight(
        tag: MistakeTag.overfoldBtn,
        count: 1,
        evLoss: 2,
        shortExplanation: '',
        examples: const [],
      ),
    ];
    final engine = GoalSmartSuggestionEngine(
      insights: _FakeInsights(insights),
      library: _FakeLibrary(lessons),
      status: _FakeStatus({'l2': BoosterLessonStatus.repeated}),
      tuner: _FakeTuner({'push': 1.3, 'call': 1.5, 'fold': 0.8}),
    );
    final goals = await engine.generateGoals();
    expect(goals.length, 1);
    expect(goals.first.id, 'l1');
  });
}
