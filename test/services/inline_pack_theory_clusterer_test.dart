import 'package:test/test.dart';

import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_pack_theory_clusterer.dart';

class _TestNoveltyGuard extends PackNoveltyGuardService {
  const _TestNoveltyGuard();

  @override
  bool isNovel(Set<String> tags, List<String> itemIds) {
    // Treat clusters containing the tag 'push' as non novel.
    return !tags.contains('push');
  }
}

void main() {
  group('InlinePackTheoryClusterer', () {
    final library = [
      const TheoryResource(
        id: 't1',
        title: 'Push Theory',
        uri: 'uri1',
        tags: ['push'],
      ),
      const TheoryResource(
        id: 't2',
        title: 'BB Defense',
        uri: 'uri2',
        tags: ['bb', 'defense'],
      ),
    ];

    final pack = TrainingPackModel(
      id: 'p1',
      title: 'pack',
      spots: [
        TrainingPackSpot(id: 's1', tags: ['push']),
        TrainingPackSpot(id: 's2', tags: ['bb', 'defense']),
      ],
      metadata: {},
    );

    test('deterministic clustering with ranking and novelty guard', () {
      final clusterer = InlinePackTheoryClusterer(
        noveltyGuard: const _TestNoveltyGuard(),
      );
      final result = clusterer
          .attach(pack, library, mistakeTelemetry: {'push': 0.4, 'bb': 0.8});
      final clusters = (result.metadata['theoryClusters'] as List)
          .cast<Map<String, dynamic>>();
      expect(clusters.length, 1); // push cluster skipped by novelty guard
      expect(clusters.first['theme'], 'bb');

      final spotLinks = (result.spots[1].meta['theoryLinks'] as List)
          .cast<Map<String, dynamic>>();
      expect(spotLinks, isNotEmpty);
      expect(spotLinks.first['id'], 't2');
      expect(spotLinks.first['reason'], isNotEmpty);

      final again = clusterer
          .attach(pack, library, mistakeTelemetry: {'push': 0.4, 'bb': 0.8});
      expect(again.metadata['theoryClusters'], clusters);
    });
  });
}
