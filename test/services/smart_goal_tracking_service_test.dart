import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/smart_goal_tracking_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());

  @override
  Future<void> load() async {}

  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('compute progress from logs', () async {
    SharedPreferences.setMockInitialValues({});
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'cbet_ip',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 8,
        mistakeCount: 2,
      ),
    ];
    final service = SmartGoalTrackingService(logs: _FakeLogService(logs));
    final progress = await service.getGoalProgress('cbet');
    expect(progress.stagesCompleted, 1);
    expect(progress.averageAccuracy, closeTo(80, 0.1));
  });
}
