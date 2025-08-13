import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/pack_suggestion_analytics_engine.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/suggested_training_packs_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> _list;
  _FakeLogService(this._list) : super(sessions: TrainingSessionService());

  @override
  Future<void> load() async {}

  @override
  List<SessionLog> get logs => List.unmodifiable(_list);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aggregates engagement stats', () async {
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'a',
      source: 't',
    );
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'a',
      source: 't',
    );
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'b',
      source: 't',
    );

    final now = DateTime.now();
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'a',
        startedAt: now,
        completedAt: now,
        correctCount: 1,
        mistakeCount: 0,
      ),
      SessionLog(
        tags: const [],
        sessionId: '2',
        templateId: 'b',
        startedAt: now,
        completedAt: now,
        correctCount: 1,
        mistakeCount: 0,
      ),
      SessionLog(
        tags: const [],
        sessionId: '3',
        templateId: 'c',
        startedAt: now,
        completedAt: now,
        correctCount: 1,
        mistakeCount: 0,
      ),
    ];
    final service = PackSuggestionAnalyticsEngine(logs: _FakeLogService(logs));
    final stats = await service.getStats();
    final a = stats.firstWhere((e) => e.packId == 'a');
    final b = stats.firstWhere((e) => e.packId == 'b');
    final c = stats.firstWhere((e) => e.packId == 'c');
    expect(a.shownCount, 2);
    expect(a.startedCount, 1);
    expect(b.shownCount, 1);
    expect(c.shownCount, 0);
  });
}
