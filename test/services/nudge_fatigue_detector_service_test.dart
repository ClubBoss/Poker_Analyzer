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
      // simulate open happened more than a week ago
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'pinned_open_last_b',
        DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      );
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

  test('re-engagement removes fatigue', () async {
    const item = PinnedLearningItem(type: 'lesson', id: 'd');
    for (var i = 0; i < 3; i++) {
      await logger.logDismissed(item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'pinned_open_last_d',
      DateTime.now().millisecondsSinceEpoch,
    );
    expect(await detector.isFatigued(item), false);
  });

  test('fatigue resets after cooldown', () async {
    const item = PinnedLearningItem(type: 'lesson', id: 'e');
    for (var i = 0; i < 3; i++) {
      await logger.logDismissed(item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'pinned_dismiss_last_e',
      DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch,
    );
    expect(await detector.isFatigued(item), false);
  });
}
