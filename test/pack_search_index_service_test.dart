import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_search_index_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('builds index and searches templates', () async {
    final t1 = TrainingPackTemplateV2(
      id: '1',
      name: 'Aggressive Push',
      description: 'Best push strategies',
      trainingType: TrainingType.pushFold,
      tags: ['push', 'aggression'],
    );
    final t2 = TrainingPackTemplateV2(
      id: '2',
      name: 'ICM Defense',
      description: 'ICM call strategies',
      trainingType: TrainingType.icm,
      tags: ['call', 'icm'],
    );

    await PackSearchIndexService.instance.buildIndex([t1, t2]);

    final res1 = PackSearchIndexService.instance.search('aggression');
    expect(res1, contains(t1));

    final res2 = PackSearchIndexService.instance.search('ICM');
    expect(res2, contains(t2));

    final res3 = PackSearchIndexService.instance.search('push');
    expect(res3, contains(t1));
  });
}
