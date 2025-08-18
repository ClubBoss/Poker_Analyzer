import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/theory_inbox_banner_controller.dart';
import 'package:poker_analyzer/services/theory_inbox_banner_engine.dart';
import 'package:poker_analyzer/services/booster_suggestion_engine.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeBooster extends BoosterSuggestionEngine {
  final List<TheoryMiniLessonNode> lessons;
  const _FakeBooster(this.lessons);
  @override
  Future<List<TheoryMiniLessonNode>> getRecommendedBoosters({
    int maxCount = 3,
  }) async {
    return lessons.take(maxCount).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shows banner when lesson available', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final engine = TheoryInboxBannerEngine(
      booster: const _FakeBooster([lesson]),
    );
    final controller = TheoryInboxBannerController(engine: engine);
    await controller.start(interval: Duration.zero);
    expect(controller.shouldShowInboxBanner(), isTrue);
    expect(controller.getLesson()?.id, 'l1');
    controller.dispose();
  });

  test('hidden when no lessons', () async {
    final engine = TheoryInboxBannerEngine(booster: const _FakeBooster([]));
    final controller = TheoryInboxBannerController(engine: engine);
    await controller.start(interval: Duration.zero);
    expect(controller.shouldShowInboxBanner(), isFalse);
    expect(controller.getLesson(), isNull);
    controller.dispose();
  });
}
