import '../models/line_pattern.dart';
import '../models/line_graph_result.dart';
import '../models/spot_seed.dart';
import '../models/board.dart';
import '../models/card_model.dart';
import 'board_splitter.dart';

class LineGraphEngine {
  const LineGraphEngine();

  LineGraphResult build(LinePattern pattern) {
    final Map<String, List<HandActionNode>> streets = {};
    final List<String> tags = [];

    pattern.streets.forEach((street, actions) {
      final nodes = <HandActionNode>[];
      for (final act in actions) {
        final actor = _inferActor(act);
        final tag = '${street}${_capitalize(act)}';
        nodes.add(HandActionNode(actor: actor, action: act, tag: tag));
        tags.add(tag);
      }
      streets[street] = nodes;
    });

    return LineGraphResult(
      heroPosition: pattern.startingPosition ?? 'hero',
      streets: streets,
      tags: tags,
    );
  }

  String _inferActor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('villain')) {
      return 'villain';
    }
    return 'hero';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  List<SpotSeed> expandLine({
    required String preflopAction,
    required String line,
    required List<CardModel> board,
    required List<CardModel> hand,
    required String position,
  }) {
    final split = BoardSplitter.split(board);
    final streets = <String>[];
    if (split.flop.isNotEmpty) streets.add('flop');
    if (split.turn != null) streets.add('turn');
    if (split.river != null) streets.add('river');

    final actions = line
        .split('-')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final grouped = _groupActions(actions, streets.length);

    final seeds = <SpotSeed>[];
    final history = <String>[];
    if (preflopAction.isNotEmpty) {
      history.add(preflopAction);
    }
    for (var i = 0; i < streets.length; i++) {
      seeds.add(
        SpotSeed(
          board: _boardUpTo(split, i),
          hand: hand,
          position: position,
          previousActions: List<String>.from(history),
          targetStreet: streets[i],
        ),
      );
      history.addAll(grouped[i]);
    }
    return seeds;
  }

  List<List<String>> _groupActions(List<String> actions, int streetCount) {
    final groups = <List<String>>[];
    var index = 0;
    var remaining = actions.length;
    for (
      var remainingStreets = streetCount;
      remainingStreets > 0;
      remainingStreets--
    ) {
      final minForRest = remainingStreets - 1;
      var size = remaining - minForRest;
      if (size < 0) size = 0;
      final end = index + size;
      groups.add(actions.sublist(index, end));
      index = end;
      remaining -= size;
    }
    return groups;
  }

  List<CardModel> _boardUpTo(Board board, int index) {
    switch (index) {
      case 0:
        return List<CardModel>.from(board.flop);
      case 1:
        return [...board.flop, if (board.turn != null) board.turn!];
      case 2:
        return [
          ...board.flop,
          if (board.turn != null) board.turn!,
          if (board.river != null) board.river!,
        ];
      default:
        return [];
    }
  }
}
