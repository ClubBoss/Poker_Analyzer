import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_pack_library_metadata_enricher.dart';

void main() {
  test('enrichAll populates UX metadata for all packs', () {
    final lib = TrainingPackLibraryV2.instance;
    lib.clear();

    final p1 = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack1',
      tags: ['river', 'icm'],
      trainingType: TrainingType.postflop,
      spots: [],
      spotCount: 5,
      gameType: GameType.tournament,
      targetStreet: 'river',
      meta: {'skillLevel': 'advanced'},
    );

    final p2 = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Pack2',
      tags: ['starter', 'flop'],
      trainingType: TrainingType.postflop,
      spots: [],
      spotCount: 30,
      gameType: GameType.cash,
      targetStreet: 'flop',
    );

    lib.addPack(p1);
    lib.addPack(p2);

    final enricher = TrainingPackLibraryMetadataEnricher(library: lib);
    enricher.enrichAll();

    expect(p1.meta['level'], 'advanced');
    expect(p1.meta['topic'], 'postflop');
    expect(p1.meta['format'], 'tournament');
    expect(p1.meta['complexity'], 'icm');

    expect(p2.meta['level'], 'beginner');
    expect(p2.meta['topic'], 'postflop');
    expect(p2.meta['format'], 'cash');
    expect(p2.meta['complexity'], 'multiStreet');
  });
}
