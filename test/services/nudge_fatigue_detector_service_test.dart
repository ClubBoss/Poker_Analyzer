import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/pinned_learning_item.dart';
import 'package:poker_analyzer/services/nudge_fatigue_detector_service.dart';
import 'package:poker_analyzer/services/pinned_interaction_logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final logger = PinnedInteractionLoggerService.instance;
  final detector = NudgeFatigueDetectorService.instance;

  test('fatigued after many dismissals with no opens', () async {
    const item = PinnedLearningItem(type: 'lesson', id: 'a');
    for (var i = 0; i < 3; i++) {
      await logger.logDismissed(item);
    }
    expect(await detector.isFatigued(item), true);
  });

  test(
    'fatigued when open to dismiss ratio low with enough impressions',
    () async {
      const item = PinnedLearningItem(type: 'pack', id: 'b');
      for (var i = 0; i < 10; i++) {
        await logger.logImpression(item);
      }
      await logger.logOpened(item);
      for (var i = 0; i < 6; i++) {
        await logger.logDismissed(item);
      }
      expect(await detector.isFatigued(item), true);
    },
  );

  test('not fatigued when engagement reasonable', () async {
    const item = PinnedLearningItem(type: 'pack', id: 'c');
    for (var i = 0; i < 6; i++) {
      await logger.logImpression(item);
    }
    await logger.logOpened(item);
    await logger.logOpened(item);
    for (var i = 0; i < 5; i++) {
      await logger.logDismissed(item);
    }
    expect(await detector.isFatigued(item), false);
  });
}
