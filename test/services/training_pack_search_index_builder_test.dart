import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/pack_ux_metadata.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_pack_search_index_builder.dart';

void main() {
  test('filters by multiple metadata fields and tags', () {
    final p1 = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Beginner Postflop',
      trainingType: TrainingType.postflop,
      tags: ['postflop'],
      meta: {
        'level': TrainingPackLevel.beginner.name,
        'topic': TrainingPackTopic.postflop.name,
        'format': TrainingPackFormat.tournament.name,
        'complexity': TrainingPackComplexity.simple.name,
      },
    );
    final p2 = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Beginner 3bet',
      trainingType: TrainingType.postflop,
      tags: ['3bet'],
      meta: {
        'level': TrainingPackLevel.beginner.name,
        'topic': TrainingPackTopic.threeBet.name,
        'format': TrainingPackFormat.tournament.name,
        'complexity': TrainingPackComplexity.multiStreet.name,
      },
    );
    final p3 = TrainingPackTemplateV2(
      id: 'p3',
      name: 'Intermediate 3bet',
      trainingType: TrainingType.postflop,
      tags: ['3bet', 'extra'],
      meta: {
        'level': TrainingPackLevel.intermediate.name,
        'topic': TrainingPackTopic.threeBet.name,
        'format': TrainingPackFormat.tournament.name,
        'complexity': TrainingPackComplexity.multiStreet.name,
      },
    );
    final p4 = TrainingPackTemplateV2(
      id: 'p4',
      name: 'Intermediate 3bet Cash',
      trainingType: TrainingType.postflop,
      tags: ['3bet'],
      meta: {
        'level': TrainingPackLevel.intermediate.name,
        'topic': TrainingPackTopic.threeBet.name,
        'format': TrainingPackFormat.cash.name,
        'complexity': TrainingPackComplexity.multiStreet.name,
      },
    );

    final builder = TrainingPackSearchIndexBuilder();
    builder.build([p1, p2, p3, p4]);

    final res = builder.query(
      level: TrainingPackLevel.intermediate,
      topic: TrainingPackTopic.threeBet,
      format: TrainingPackFormat.tournament,
      complexity: TrainingPackComplexity.multiStreet,
      tags: ['3bet', 'extra'],
    );

    expect(res, [p3]);
  });
}
