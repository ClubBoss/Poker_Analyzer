import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/services/audit_log_storage_service.dart';
import 'package:poker_analyzer/services/training_pack_audit_log_service.dart';

void main() {
  test('records changes between packs', () async {
    final dir = await Directory.systemTemp.createTemp();
    final storage = AuditLogStorageService(
        filePath: '${dir.path}/audit.json');
    final service = TrainingPackAuditLogService(storage: storage);

    final oldPack = TrainingPackModel(
      id: 'p1',
      title: 'Old',
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      tags: ['a'],
      metadata: {'level': 1},
    );
    final newPack = TrainingPackModel(
      id: 'p1',
      title: 'New',
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData()),
        TrainingPackSpot(id: 's2', hand: HandData()),
      ],
      tags: ['b'],
      metadata: {'level': 2},
    );

    await service.recordChange(oldPack, newPack, userId: 'tester',
        timestamp: DateTime.utc(2024, 1, 1));
    final logs = await storage.query();
    expect(logs.length, 1);
    final entry = logs.first;
    expect(entry.packId, 'p1');
    expect(entry.userId, 'tester');
    expect(entry.changedFields,
        containsAll(['title', 'tags', 'spots', 'metadata']));
    expect(entry.diffSnapshot['title']['old'], 'Old');
    expect(entry.diffSnapshot['title']['new'], 'New');
    await dir.delete(recursive: true);
  });
}
