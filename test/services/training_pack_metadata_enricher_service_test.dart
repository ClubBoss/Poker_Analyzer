import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/services/training_pack_metadata_enricher_service.dart';
import 'package:poker_analyzer/services/training_pack_audit_log_service.dart';

class _FakeAuditService extends TrainingPackAuditLogService {
  int calls = 0;
  @override
  Future<void> recordChange(TrainingPackModel oldPack, TrainingPackModel newPack,
      {String userId = 'unknown', DateTime? timestamp}) async {
    calls++;
  }
}

void main() {
  test('enriches metadata and records audit when changed', () async {
    final spot1 = TrainingPackSpot(
      id: 's1',
      street: 0,
      hand: HandData(
        heroIndex: 0,
        stacks: {'0': 30, '1': 30},
        actions: {
          0: [
            ActionEntry(0, 1, 'limp'),
            ActionEntry(0, 0, 'raise', amount: 3),
          ],
        },
      ),
    );
    final spot2 = TrainingPackSpot(
      id: 's2',
      street: 2,
      board: ['As', 'Ks', 'Qh', 'Jd'],
      hand: HandData(
        heroIndex: 0,
        stacks: {'0': 70, '1': 70},
        actions: {
          0: [
            ActionEntry(0, 0, 'raise', amount: 2),
            ActionEntry(0, 1, 'call'),
          ],
          1: [
            ActionEntry(1, 0, 'bet', amount: 3),
            ActionEntry(1, 1, 'call'),
          ],
        },
      ),
    );
    final pack = TrainingPackModel(
      id: 'p1',
      title: 'Test',
      spots: [spot1, spot2],
      metadata: const {},
    );

    final audit = _FakeAuditService();
    final service = TrainingPackMetadataEnricherService(audit: audit);

    final enriched = await service.enrich(pack);
    expect(enriched.metadata['numSpots'], 2);
    expect(enriched.metadata['hasLimpedPots'], isTrue);
    expect(enriched.metadata['streets'], 'flop+turn');
    expect(enriched.metadata['difficulty'], 'hard');
    expect(enriched.metadata['stackSpread'], {'min': 30.0, 'max': 70.0});
    expect(audit.calls, 1);

    // running again should not trigger another audit as metadata stays same
    await service.enrich(enriched);
    expect(audit.calls, 1);
  });
}

