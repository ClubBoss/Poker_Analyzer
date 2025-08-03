import '../models/board_stages.dart';
import '../models/card_model.dart';
import '../helpers/board_filtering_params_builder.dart';
import 'board_texture_filter_service.dart';
import 'card_deck_service.dart';
import 'board_filtering_service_v2.dart';

class FullBoardGenerator {
  const FullBoardGenerator({
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
    BoardFilteringServiceV2? boardFilter,
  })  : _deckService = deckService ?? const CardDeckService(),
        _textureFilter = textureFilter ?? const BoardTextureFilterService(),
        _boardFilter = boardFilter ?? const BoardFilteringServiceV2();

  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;
  final BoardFilteringServiceV2 _boardFilter;

  /// Generates all possible flop-turn-river combinations that satisfy
  /// [constraints].
  ///
  /// Supported constraint keys include:
  /// * `texture` (e.g. `paired`)
  /// * `rainbow` (bool)
  /// * `broadwayHeavy` (bool)
  /// * `drawy` (bool)
  /// * `low` (bool)
  /// * `paired` (bool)
  /// * `aceHigh` (bool)
  /// * `requiredRanks` (List<String>)
  /// * `requiredSuits` (List<String>)
  List<BoardStages> generate(Map<String, dynamic> constraints) {
    final tags = <String>[];
    final requiredRanks = <String>[
      for (final r in (constraints['requiredRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    ];
    final requiredSuits = <String>[
      for (final s in (constraints['requiredSuits'] as List? ?? []))
        s.toString(),
    ];

    final texture = constraints['texture'];
    if (texture != null) tags.add(texture.toString());
    if (constraints['rainbow'] == true) tags.add('rainbow');
    if (constraints['broadwayHeavy'] == true) tags.add('broadway');
    if (constraints['drawy'] == true) tags.add('connected');
    if (constraints['low'] == true) tags.add('low');
    if (constraints['paired'] == true) tags.add('paired');
    if (constraints['aceHigh'] == true) tags.add('aceHigh');

    final filter = BoardFilteringParamsBuilder.build(tags);
    if (requiredRanks.isNotEmpty) filter['requiredRanks'] = requiredRanks;
    if (requiredSuits.isNotEmpty) filter['requiredSuits'] = requiredSuits;

    final requiredTags = <String>{
      for (final t in (constraints['requiredTags'] as List? ?? []))
        t.toString(),
    };
    final excludedTags = <String>{
      for (final t in (constraints['excludedTags'] as List? ?? []))
        t.toString(),
    };

    final deck = _deckService.buildDeck();
    final results = <BoardStages>[];

    for (var i = 0; i < deck.length - 2; i++) {
      for (var j = i + 1; j < deck.length - 1; j++) {
        for (var k = j + 1; k < deck.length; k++) {
          final flop = [deck[i], deck[j], deck[k]];
          if (!_textureFilter.isMatch(flop, filter)) {
            continue;
          }
          final remaining = [
            for (final c in deck)
              if (!flop.contains(c)) c
          ];
          for (var t = 0; t < remaining.length - 1; t++) {
            for (var r = t + 1; r < remaining.length; r++) {
              final turn = remaining[t];
              final river = remaining[r];
              final board = BoardStages(
                flop: flop.map((c) => c.toString()).toList(),
                turn: turn.toString(),
                river: river.toString(),
              );
              if (!_boardFilter.isMatch(board, requiredTags,
                  excludedTags: excludedTags)) {
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
}
