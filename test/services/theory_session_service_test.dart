import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_session_service.dart';
import 'package:poker_analyzer/services/theory_booster_recommender.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeRecommender extends TheoryBoosterRecommender {
  final BoosterRecommendationResult? result;
  const _FakeRecommender(this.result);
  @override
  Future<BoosterRecommendationResult?> recommend(TheoryMiniLessonNode lesson,
      {List recentMistakes = const []}) async {
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onComplete marks lesson and returns recommendation', () async {
    SharedPreferences.setMockInitialValues({});
    final rec = const BoosterRecommendationResult(
      boosterId: 'b',
      reasonTag: 'tag',
      priority: 1.0,
      origin: 'lesson',
    );
    final service = TheorySessionService(
      recommender: const _FakeRecommender(rec),
    );
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: const [],
    );
    final res = await service.onComplete(lesson);
    expect(res, isNotNull);
    expect(res!.boosterId, 'b');
    expect(res.origin, 'lesson');
    final completed = await service.progress.isCompleted('l1');
    expect(completed, true);
  });
}
