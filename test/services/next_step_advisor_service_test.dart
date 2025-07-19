import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/next_step_advisor_service.dart';

void main() {
  const service = NextStepAdvisorService();

  test('recommends repeating mistakes when ev or icm negative', () {
    const stats = LearningStats(
      completedPacks: 0,
      accuracy: 0.7,
      ev: -1,
      icm: 0,
      starterPathCompleted: false,
      customPathStarted: false,
      hasWeakTags: false,
      hasMistakes: true,
    );
    final advice = service.recommend(stats: stats);
    expect(advice.title, 'Повторить ошибки');
  });

  test('recommends training weaknesses when weak tags present', () {
    const stats = LearningStats(
      completedPacks: 2,
      accuracy: 0.9,
      ev: 0,
      icm: 0,
      starterPathCompleted: false,
      customPathStarted: false,
      hasWeakTags: true,
      hasMistakes: false,
    );
    final advice = service.recommend(stats: stats);
    expect(advice.title, 'Прокачать слабые места');
  });

  test('recommends finishing starter path when not completed', () {
    const stats = LearningStats(
      completedPacks: 5,
      accuracy: 0.9,
      ev: 0,
      icm: 0,
      starterPathCompleted: false,
      customPathStarted: false,
      hasWeakTags: false,
      hasMistakes: false,
    );
    final advice = service.recommend(stats: stats);
    expect(advice.title, 'Завершить Starter Path');
  });

  test('recommends starting new path when starter done but no custom', () {
    const stats = LearningStats(
      completedPacks: 5,
      accuracy: 0.9,
      ev: 0,
      icm: 0,
      starterPathCompleted: true,
      customPathStarted: false,
      hasWeakTags: false,
      hasMistakes: false,
    );
    final advice = service.recommend(stats: stats);
    expect(advice.title, 'Начать новый путь');
  });

  test('fallback to playing recommended pack', () {
    const stats = LearningStats(
      completedPacks: 5,
      accuracy: 0.95,
      ev: 1,
      icm: 1,
      starterPathCompleted: true,
      customPathStarted: true,
      hasWeakTags: false,
      hasMistakes: false,
    );
    final advice = service.recommend(stats: stats);
    expect(advice.title, 'Сыграть рекомендованный пак');
  });
}
