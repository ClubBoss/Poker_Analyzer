import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/pack_quality_inspector_service.dart';

void main() {
  test('detects structural issues in a pack', () {
    final base = TrainingPackSpot(
      id: 's1',
      tags: ['push'],
      board: ['Ah', 'Kd', 'Qs'],
    );

    final spots = [
      base,
      base.copyWith(id: 's2'),
      base.copyWith(id: 's3'),
    ];
    final pack = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);

    final issues =
        PackQualityInspectorService.instance.analyzePack(pack);
    final ids = issues.map((e) => e.id).toSet();

    expect(ids.contains('overused_tag'), true);
    expect(ids.contains('missing_theory_links'), true);
    expect(ids.contains('low_board_diversity'), true);
    expect(ids.contains('duplicate_spots'), true);
    expect(ids.contains('too_few_spots'), true);
  });
}

