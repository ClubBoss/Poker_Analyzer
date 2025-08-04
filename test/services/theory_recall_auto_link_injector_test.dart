import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_usage_event.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/inline_theory_linker_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_usage_tracker.dart';
import 'package:poker_analyzer/services/theory_recall_auto_link_injector.dart';
import 'package:poker_analyzer/services/theory_auto_injection_logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final bool decayed;
  const _FakeRetention(this.decayed);
  @override
  Future<bool> isDecayed(String tag, {double threshold = 30}) async => decayed;
}

class _FakeLinker extends InlineTheoryLinkerService {
  final List<String> ids;
  _FakeLinker(this.ids);
  @override
  Future<List<String>> getLinkedLessonIdsForSpot(spot) async => ids;
}

class _FakeUsageTracker implements TheoryMiniLessonUsageTracker {
  final List<TheoryMiniLessonUsageEvent> events;
  _FakeUsageTracker(this.events);
  @override
  Future<void> logManualOpen(String lessonId, String source) async {}
  @override
  Future<List<TheoryMiniLessonUsageEvent>> getRecent({int limit = 50}) async =>
      events.take(limit).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TheoryAutoInjectionLoggerService.instance.resetForTest();
  });

  test('injects linkedTheoryId for decayed spot', () async {
    final spot = TrainingPackSpot(id: 's1', tags: ['push']);
    final service = TheoryRecallAutoLinkInjector(
      retention: const _FakeRetention(true),
      linker: _FakeLinker(['l1']),
      usageTracker: _FakeUsageTracker(const []),
    );
    await service.inject(spot);
    expect(spot.meta['linkedTheoryId'], 'l1');
    final logs = await TheoryAutoInjectionLoggerService.instance.getRecentLogs();
    expect(logs.length, 1);
    expect(logs.first.lessonId, 'l1');
    expect(logs.first.spotId, 's1');
  });

  test('skips when lesson already opened', () async {
    final spot = TrainingPackSpot(id: 's2', tags: ['push']);
    final service = TheoryRecallAutoLinkInjector(
      retention: const _FakeRetention(true),
      linker: _FakeLinker(['l1']),
      usageTracker: _FakeUsageTracker([
        TheoryMiniLessonUsageEvent(
          lessonId: 'l1',
          source: 'manual',
          timestamp: DateTime.now(),
        ),
      ]),
    );
    await service.inject(spot);
    expect(spot.meta.containsKey('linkedTheoryId'), false);
  });
}
