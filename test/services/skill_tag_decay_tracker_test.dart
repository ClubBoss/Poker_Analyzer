import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/models/tag_xp_history_entry.dart';
import 'package:poker_analyzer/services/skill_tag_decay_tracker.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

class _FakeHistoryService extends TagMasteryHistoryService {
  final Map<String, List<TagXpHistoryEntry>> map;
  _FakeHistoryService(this.map);
  @override
  Future<Map<String, List<TagXpHistoryEntry>>> getHistory() async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects decaying tags by trend and inactivity', () async {
    final now = DateTime(2024, 1, 10);
    final logs = [
      SessionLog(
        sessionId: 's1',
        templateId: 't1',
        startedAt: now.subtract(const Duration(days: 10)),
        completedAt: now.subtract(const Duration(days: 10)),
        correctCount: 9,
        mistakeCount: 1,
        tags: const ['push'],
      ),
      SessionLog(
        sessionId: 's2',
        templateId: 't1',
        startedAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 7)),
        correctCount: 8,
        mistakeCount: 2,
        tags: const ['push'],
      ),
      SessionLog(
        sessionId: 's3',
        templateId: 't1',
        startedAt: now.subtract(const Duration(days: 4)),
        completedAt: now.subtract(const Duration(days: 4)),
        correctCount: 7,
        mistakeCount: 3,
        tags: const ['push'],
      ),
      SessionLog(
        sessionId: 's4',
        templateId: 't2',
        startedAt: now.subtract(const Duration(days: 3)),
        completedAt: now.subtract(const Duration(days: 3)),
        correctCount: 7,
        mistakeCount: 3,
        tags: const ['call'],
      ),
      SessionLog(
        sessionId: 's5',
        templateId: 't2',
        startedAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 2)),
        correctCount: 8,
        mistakeCount: 2,
        tags: const ['call'],
      ),
      SessionLog(
        sessionId: 's6',
        templateId: 't2',
        startedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
        correctCount: 9,
        mistakeCount: 1,
        tags: const ['call'],
      ),
    ];

    final history = {
      'push': [
        TagXpHistoryEntry(
            date: now.subtract(const Duration(days: 4)), xp: 5, source: '')
      ],
      'call': [
        TagXpHistoryEntry(
            date: now.subtract(const Duration(days: 1)), xp: 5, source: '')
      ],
    };

    final service = SkillTagDecayTracker(
      logs: _FakeLogService(logs),
      history: _FakeHistoryService(history),
    );

    final decayed = await service.getDecayingTags(maxTags: 2, now: now);
    expect(decayed, contains('push'));
    expect(decayed, isNot(contains('call')));
  });
}
