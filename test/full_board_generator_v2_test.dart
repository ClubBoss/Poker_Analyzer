import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/full_board_generator_v2.dart';
import 'package:poker_analyzer/services/board_filtering_service_v2.dart';
import 'package:poker_analyzer/services/board_cluster_library.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  test('supports texture and suit/rank filters', () {
    const generator = FullBoardGeneratorV2();
    final boards = generator.generate({
      'requiredTextures': ['paired', 'rainbow'],
      'requiredRanks': ['A', 'K'],
      'excludedSuits': ['h'],
    });
    expect(boards, isNotEmpty);
    for (final b in boards) {
      final flopRanks = b.flop.map((c) => c[0]).toList();
      final flopSuits = b.flop.map((c) => c[1]).toList();
      final hasPair = flopRanks.toSet().length < flopRanks.length;
      expect(hasPair, isTrue);
      expect(flopSuits.toSet().length, 3);
      final all = [...b.flop, b.turn, b.river];
      expect(all.map((c) => c[0]).toSet().containsAll({'A', 'K'}), isTrue);
      expect(all.any((c) => c[1] == '♥'), isFalse);
    }
  });

  test('applies advanced board filtering', () {
    const generator = FullBoardGeneratorV2();
    final boards = generator.generate({
      'requiredRanks': ['A', 'K', 'Q'],
      'requiredTags': ['broadwayHeavy'],
      'excludedTags': ['fourToFlush'],
    });
    expect(boards, isNotEmpty);
    const svc = BoardFilteringServiceV2();
    for (final b in boards) {
      expect(
        svc.isMatch(b, {'broadwayHeavy'}, excludedTags: {'fourToFlush'}),
        isTrue,
      );
    }
  });

  test('supports cluster-based filters', () {
    const generator = FullBoardGeneratorV2();
    final boards = generator.generate(
      {
        'requiredRanks': ['A', 'K', 'Q', 'J', 'T'],
      },
      requiredBoardClusters: ['broadway-heavy'],
      excludedBoardClusters: ['trap'],
    );
    expect(boards, isNotEmpty);
    for (final b in boards) {
      final cards = [
        ...b.flop,
        b.turn,
        b.river,
      ].map((c) => CardModel(rank: c[0], suit: c[1])).toList();
      final clusters = BoardClusterLibrary.getClusters(
        cards,
      ).map((c) => c.toLowerCase()).toSet();
      expect(clusters.contains('broadway-heavy'), isTrue);
      expect(clusters.contains('trap'), isFalse);
    }
    final none = generator.generate(
      {
        'requiredRanks': ['A', 'K', 'Q', 'J', 'T'],
      },
      excludedBoardClusters: ['broadway-heavy'],
    );
    expect(none, isEmpty);
  });
}
