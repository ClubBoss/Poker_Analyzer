import 'package:intl/intl.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/completed_session_summary_service.dart';
import 'package:poker_analyzer/presenters/completed_session_history_presenter.dart';
import 'package:test/test.dart';

void main() {
  Intl.defaultLocale = 'en_US';

  test('presenter converts summaries to display items', () {
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Push/Fold SB vs BB',
      trainingType: TrainingType.quiz,
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
    );

    final summary = CompletedSessionSummary(
      fingerprint: 'fp1',
      trainingType: 'quiz',
      accuracy: 0.88,
      timestamp: DateTime.utc(2024, 7, 2),
      yaml: pack.toYamlString(),
    );

    const presenter = CompletedSessionHistoryPresenter();
    final items = presenter.present([summary]);

    expect(items, hasLength(1));
    expect(items.first.title, 'Quiz Pack: Push/Fold SB vs BB');
    expect(items.first.subtitle, 'Completed on Jul 2, 2024, Accuracy: 88%');
    expect(items.first.fingerprint, 'fp1');
    expect(items.first.timestamp, DateTime.utc(2024, 7, 2));
  });
}
