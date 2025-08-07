import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/repositories/training_session_log_repository.dart';
import 'package:poker_analyzer/services/pack_format_selection_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_run_ab_comparator_service.dart';
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
  group('PackFormatSelectionService', () {
    test('selects variant with best metrics', () {
      final logs = <SessionLog>[
        // Variant A
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
          sessionId: 'a3',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 3, 0, 0, 0),
          completedAt: DateTime(2023, 1, 3, 0, 1, 0),
          correctCount: 9,
          mistakeCount: 1,
          tags: const ['vA'],
        ),
        // Variant B
        SessionLog(
          sessionId: 'b1',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 4, 0, 0, 0),
          completedAt: DateTime(2023, 1, 4, 0, 1, 0),
          correctCount: 5,
          mistakeCount: 5,
          tags: const ['vB'],
        ),
        SessionLog(
          sessionId: 'b2',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 5, 0, 0, 0),
          completedAt: DateTime(2023, 1, 5, 0, 1, 0),
          correctCount: 6,
          mistakeCount: 4,
          tags: const ['vB'],
        ),
        SessionLog(
          sessionId: 'b3',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 6, 0, 0, 0),
          completedAt: DateTime(2023, 1, 6, 0, 1, 0),
          correctCount: 5,
          mistakeCount: 5,
          tags: const ['vB'],
        ),
      ];

      final repo = _FakeLogRepository(logs);
      final comparator = TrainingRunABComparatorService(repository: repo);
      final service = PackFormatSelectionService(comparator: comparator);

      final id = service.selectBestVariant(
        packId: 'p',
        variantIds: const ['vA', 'vB'],
      );
      expect(id, 'vA');
    });

    test('returns null when sample sizes are insufficient', () {
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
          sessionId: 'b1',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 2, 0, 0, 0),
          completedAt: DateTime(2023, 1, 2, 0, 1, 0),
          correctCount: 5,
          mistakeCount: 5,
          tags: const ['vB'],
        ),
      ];

      final repo = _FakeLogRepository(logs);
      final comparator = TrainingRunABComparatorService(repository: repo);
      final service = PackFormatSelectionService(comparator: comparator);

      final id = service.selectBestVariant(
        packId: 'p',
        variantIds: const ['vA', 'vB'],
      );
      expect(id, isNull);
    });

    test('uses retention then earlyDrop for tie-breaking', () {
      final logs = <SessionLog>[
        // Variant A: same accuracy as B but lower retention
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
          completedAt: DateTime(2023, 1, 2, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vA'],
        ),
        SessionLog(
          sessionId: 'a3',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 3, 0, 0, 0),
          completedAt: DateTime(2023, 1, 3, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vA'],
        ),
        // Variant B with higher retention and fewer early drops
        SessionLog(
          sessionId: 'b1',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 4, 0, 0, 0),
          completedAt: DateTime(2023, 1, 4, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vB'],
        ),
        SessionLog(
          sessionId: 'b2',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 5, 0, 0, 0),
          completedAt: DateTime(2023, 1, 5, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vB'],
        ),
        SessionLog(
          sessionId: 'b3',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 6, 0, 0, 0),
          completedAt: DateTime(2023, 1, 6, 0, 1, 0),
          correctCount: 8,
          mistakeCount: 2,
          tags: const ['vB'],
        ),
        SessionLog(
          sessionId: 'b4',
          templateId: 'p',
          startedAt: DateTime(2023, 1, 7, 0, 0, 0),
          completedAt: DateTime(2023, 1, 7, 0, 0, 10),
          correctCount: 1,
          mistakeCount: 0,
          tags: const ['vB'],
        ),
      ];

      final repo = _FakeLogRepository(logs);
      final comparator = TrainingRunABComparatorService(repository: repo);
      final service = PackFormatSelectionService(comparator: comparator);

      final id = service.selectBestVariant(
        packId: 'p',
        variantIds: const ['vA', 'vB'],
      );
      expect(id, 'vB');
    });
  });
}
