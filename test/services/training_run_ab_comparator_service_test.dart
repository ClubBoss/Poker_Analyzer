import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/repositories/training_session_log_repository.dart';
import 'package:poker_analyzer/services/training_run_ab_comparator_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeLogRepository extends TrainingSessionLogRepository {
  final List<SessionLog> entries;
  _FakeLogRepository(this.entries)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  List<SessionLog> getLogs({required String packId, String? variant}) {
    return entries.where((l) {
      if (l.templateId != packId) return false;
      if (variant != null && !l.tags.contains(variant)) return false;
      return true;
    }).toList();
  }
}

void main() {
  group('TrainingRunABComparatorService', () {
    test('computes metrics for two variants', () {
      final logs = <SessionLog>[
        SessionLog(
          sessionId: 'a1',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 1, 0, 0, 0),
          completedAt: DateTime(2023, 1, 1, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vA'],
        ),
        SessionLog(
          sessionId: 'a2',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 2, 0, 0, 0),
          completedAt: DateTime(2023, 1, 2, 0, 1, 30),
          correctCount: 7,
          mistakeCount: 3,
          tags: const ['vA'],
        ),
        SessionLog(
          sessionId: 'b1',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 3, 0, 0, 0),
          completedAt: DateTime(2023, 1, 3, 0, 2, 0),
          correctCount: 5,
          mistakeCount: 5,
          tags: const ['vB'],
        ),
      ];

      final repo = _FakeLogRepository(logs);
      final service = TrainingRunABComparatorService(repository: repo);

      final result = service.compare(
        packIdA: 'p',
        packIdB: 'p',
        variantA: 'vA',
        variantB: 'vB',
      );

      expect(result.sampleSizeA, 2);
      expect(result.sampleSizeB, 1);
      expect(result.accuracyA, closeTo(0.75, 1e-9));
      expect(result.accuracyB, closeTo(0.5, 1e-9));
      expect(result.timeA, closeTo(75.0, 1e-9));
      expect(result.timeB, closeTo(120.0, 1e-9));
      expect(result.retentionA, closeTo(0.5, 1e-9));
      expect(result.retentionB, closeTo(0.0, 1e-9));
      expect(result.earlyDropA, 0);
      expect(result.earlyDropB, 0);
    });
  });
}
