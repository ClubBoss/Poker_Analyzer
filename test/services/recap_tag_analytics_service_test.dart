import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/recap_tag_analytics_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computes improvement per tag', () async {
    final logs = [
      SessionLog(
        sessionId: 'b1',
        templateId: 't1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 4,
        mistakeCount: 6,
        tags: const ['cbet'],
      ),
      SessionLog(
        sessionId: 'b2',
        templateId: 't1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 7,
        mistakeCount: 3,
        tags: const ['cbet'],
      ),
      SessionLog(
        sessionId: 'r1',
        templateId: 't1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 9,
        mistakeCount: 1,
        tags: const ['cbet', 'recap'],
      ),
    ];

    final service = RecapTagAnalyticsService(logs: _FakeLogService(logs));
    final result = await service.computeRecapTagImprovements();
    final improvement = result['cbet']?.improvement ?? 0;
    expect(improvement, closeTo(0.35, 0.01));
  });
}
