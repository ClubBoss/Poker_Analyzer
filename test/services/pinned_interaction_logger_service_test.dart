import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/pinned_learning_item.dart';
import 'package:poker_analyzer/services/pinned_interaction_logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records opens and timestamps', () async {
    final service = PinnedInteractionLoggerService.instance;
    final item = const PinnedLearningItem(type: 'pack', id: 'p1');

    await service.logOpened(item);

    expect(await service.getOpenCount('p1'), 1);
    expect(await service.getLastOpened('p1'), isNotNull);
  });

  test('tracks impressions and dismissals', () async {
    final service = PinnedInteractionLoggerService.instance;
    final item = const PinnedLearningItem(type: 'lesson', id: 'l1');

    await service.logImpression(item);
    await service.logImpression(item);
    await service.logDismissed(item);

    final stats = await service.getStatsFor('l1');
    expect(stats['impressions'], 2);
    expect(stats['dismissals'], 1);
    expect(stats['opens'], 0);
  });

  test('records dismissal time and clears fatigue', () async {
    final service = PinnedInteractionLoggerService.instance;
    const item = PinnedLearningItem(type: 'lesson', id: 'l2');

    await service.logDismissed(item);

    expect(await service.getLastDismissed('l2'), isNotNull);

    await service.clearFatigueFor('l2');

    final stats = await service.getStatsFor('l2');
    expect(stats['dismissals'], 0);
    expect(stats['lastDismissed'], isNull);
  });
}

