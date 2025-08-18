import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/spaced_review_service.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';
import 'package:poker_analyzer/services/user_error_rate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserErrorRateService.instance.reset();
  });

  test('recordMistake and promotion/demotion', () async {
    final svc = SpacedReviewService(templates: TemplateStorageService());
    await svc.init();
    await svc.recordMistake('s1', 'p1');
    final entry = svc.debugEntry('s1')!;
    final today = svc.debugEpochDay(DateTime.now());
    expect(entry.box, 1);
    expect(entry.due, today + 1);

    await svc.recordReviewOutcome('s1', 'p1', true);
    final entry2 = svc.debugEntry('s1')!;
    expect(entry2.box, 3);
    expect(entry2.due, today + 7);

    await svc.recordReviewOutcome('s1', 'p1', false);
    final entry3 = svc.debugEntry('s1')!;
    expect(entry3.box, 1);
    expect(entry3.due, today + 1);
  });

  test('dueSpotIds filters by today', () async {
    final svc = SpacedReviewService(templates: TemplateStorageService());
    await svc.init();
    await svc.recordMistake('a', 'p1');
    await svc.recordMistake('b', 'p1');
    svc.debugEntry('b')!.due = svc.debugEpochDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final dueToday = svc.dueSpotIds(DateTime.now());
    expect(dueToday, contains('b'));
    expect(dueToday, isNot(contains('a')));
  });

  test('ewma high clamps box', () async {
    final svc = SpacedReviewService(templates: TemplateStorageService());
    await svc.init();
    for (var i = 0; i < 3; i++) {
      await UserErrorRateService.instance.recordAttempt(
        packId: 'p2',
        tags: {'t'},
        isCorrect: false,
        ts: DateTime.now(),
      );
    }
    await svc.recordMistake('s2', 'p2');
    await svc.recordReviewOutcome('s2', 'p2', true);
    final entry = svc.debugEntry('s2')!;
    expect(entry.box, lessThanOrEqualTo(3));
  });
}
