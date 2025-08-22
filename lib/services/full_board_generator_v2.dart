import '../models/board_stages.dart';
import '../helpers/board_filtering_params_builder.dart';
import 'board_texture_filter_service.dart';
import 'card_deck_service.dart';
import 'board_filtering_service_v2.dart';
import 'board_cluster_library.dart';
import 'board_texture_classifier.dart';

class FullBoardGeneratorV2 {
  FullBoardGeneratorV2({
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
    BoardFilteringServiceV2? boardFilter,
    BoardTextureClassifier? classifier,
  }) : _deckService = deckService ?? const CardDeckService(),
       _textureFilter = textureFilter ?? const BoardTextureFilterService(),
       _boardFilter = boardFilter ?? const BoardFilteringServiceV2(),
       _classifier = classifier ?? const BoardTextureClassifier();

  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;
  final BoardFilteringServiceV2 _boardFilter;
  final BoardTextureClassifier _classifier;

  List<BoardStages> generate(
    Map<String, dynamic> constraints, {
    List<String> requiredBoardClusters = const [],
    List<String> excludedBoardClusters = const [],
  }) {
    final textures = <String>[
      for (final t in (constraints['requiredTextures'] as List? ?? []))
        t.toString(),
    ];
    final requiredRanks = <String>[
      for (final r in (constraints['requiredRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    ];
    final excludedRanks = <String>[
      for (final r in (constraints['excludedRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    ];
    final requiredSuits = <String>[
      for (final s in (constraints['requiredSuits'] as List? ?? []))
        _normalizeSuit(s.toString()),
    ];
    final excludedSuits = <String>[
      for (final s in (constraints['excludedSuits'] as List? ?? []))
        _normalizeSuit(s.toString()),
    ];

    final flopFilter = BoardFilteringParamsBuilder.build(textures);
    final boardRequiredTags = <String>{
      for (final t in (flopFilter['boardTexture'] as List? ?? []))
        if (t == 'broadway') 'broadwayHeavy' else t.toString(),
    };

    final requiredTags = <String>{
      ...boardRequiredTags,
      for (final t in (constraints['requiredTags'] as List? ?? []))
        t.toString(),
    };
    final excludedTags = <String>{
      for (final t in (constraints['excludedTags'] as List? ?? []))
        t.toString(),
    };

    final deck = _deckService.buildDeck(excludedRanks: excludedRanks.toSet());
    final usableDeck = [
      for (final c in deck)
        if (!excludedSuits.contains(c.suit)) c,
    ];

    final results = <BoardStages>[];
    final requiredClusterSet = {
      for (final c in requiredBoardClusters) c.toLowerCase(),
    };
    final excludedClusterSet = {
      for (final c in excludedBoardClusters) c.toLowerCase(),
    };

    for (var i = 0; i < usableDeck.length - 2; i++) {
      for (var j = i + 1; j < usableDeck.length - 1; j++) {
        for (var k = j + 1; k < usableDeck.length; k++) {
          final flop = [usableDeck[i], usableDeck[j], usableDeck[k]];
          if (!_textureFilter.isMatch(flop, flopFilter)) {
            continue;
          }
          final remaining = [
            for (final c in usableDeck)
              if (!flop.contains(c)) c,
          ];
          for (var t = 0; t < remaining.length - 1; t++) {
            for (var r = t + 1; r < remaining.length; r++) {
              final turn = remaining[t];
              final river = remaining[r];
              final all = [...flop, turn, river];
              if (requiredRanks.any(
                (rr) => !all.any((c) => c.rank.toUpperCase() == rr),
              )) {
                continue;
              }
              if (requiredSuits.any((ss) => !all.any((c) => c.suit == ss))) {
                continue;
              }
              if (excludedSuits.any((ss) => all.any((c) => c.suit == ss))) {
                continue;
              }
              final clusters = BoardClusterLibrary.getClusters(
                all,
              ).map((c) => c.toLowerCase()).toSet();
              if (requiredClusterSet.any((c) => !clusters.contains(c))) {
                continue;
              }
              if (excludedClusterSet.any(clusters.contains)) {
                continue;
              }
              final tags = _classifier.classifyCards(all);
              final board = BoardStages(
                flop: flop.map((c) => c.toString()).toList(),
                turn: turn.toString(),
                river: river.toString(),
                textureTags: tags,
              );
              if (!_boardFilter.isMatch(
                board,
                requiredTags,
                excludedTags: excludedTags,
              )) {
                continue;
              }
              results.add(board);
            }
          }
        }
      }
    }

    return results;
  }

  static String _normalizeSuit(String suit) {
    switch (suit.toLowerCase()) {
      case 's':
      case '♠':
        return '♠';
      case 'h':
      case '♥':
        return '♥';
      case 'd':
      case '♦':
        return '♦';
      case 'c':
      case '♣':
        return '♣';
      default:
        return suit;
    }
  }
}
