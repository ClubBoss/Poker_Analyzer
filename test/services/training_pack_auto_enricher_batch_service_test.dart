import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_auto_enricher_batch_service.dart';

void main() {
  test('enriches directory and saves updates', () async {
    final dir = await Directory.systemTemp.createTemp();

    const pack1 = '''
id: p1
title: Pack 1
spots:
  - id: s1
    hand: {}
''';

    const pack2 = '''
id: p2
title: Pack 2
metadata:
  difficulty: easy
  streets: preflop
  stackSpread:
    min: 0
    max: 0
  hasLimpedPots: false
  numSpots: 1
spots:
  - id: s2
    hand: {}
''';

    const invalid = 'id: x\nspots: []';

    await File('${dir.path}/p1.yaml').writeAsString(pack1);
    await File('${dir.path}/p2.yaml').writeAsString(pack2);
    await File('${dir.path}/bad.yaml').writeAsString(invalid);

    final service = TrainingPackAutoEnricherBatchService();
    final report = await service.enrichDirectory(dir.path, saveChanges: true);

    expect(report.enrichedCount, 2);
    expect(report.changedCount, 1);
    expect(report.skippedCount, 1);

    final updated = await File('${dir.path}/p1.yaml').readAsString();
    expect(updated.contains('numSpots: 1'), isTrue);

    final unchanged = await File('${dir.path}/p2.yaml').readAsString();
    expect(unchanged, pack2);

    await dir.delete(recursive: true);
  });
}
