import 'dart:math';

import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import 'full_board_generator_service.dart';

class LineGraphConfig {
  final bool keepHeroHand;
  final bool keepBoard;
  final int variationDepth;

  const LineGraphConfig({
    this.keepHeroHand = true,
    this.keepBoard = true,
    this.variationDepth = 0,
  });
}

class LineGraphRequest {
  final SpotSeedFormat root;
  final int stages;
  final LineGraphConfig config;

  const LineGraphRequest({
    required this.root,
    required this.stages,
    this.config = const LineGraphConfig(),
  });
}

class LineGraphEngine {
  LineGraphEngine({FullBoardGeneratorService? boardGenerator, Random? random})
      : _boardGenerator =
            boardGenerator ?? FullBoardGeneratorService(random: random ?? Random());

  final FullBoardGeneratorService _boardGenerator;

  List<SpotSeedFormat> generate(LineGraphRequest request) {
    final spots = <SpotSeedFormat>[];
    var current = request.root;
    spots.add(current);
    for (var i = 1; i < request.stages; i++) {
      current = _nextSpot(current, request);
      spots.add(current);
    }
    return spots;
  }

  SpotSeedFormat _nextSpot(SpotSeedFormat current, LineGraphRequest req) {
    final nextStage = current.board.length + 1;
    List<CardModel> board = current.board;
    if (req.config.keepBoard) {
      final generated = _boardGenerator.generateBoard(
        FullBoardRequest(
          stages: nextStage,
          excludedCards: current.board,
        ),
      );
      board = List<CardModel>.from(current.board)..add(generated.cards.last);
    }

    // maintain villain actions prefix
    final villain = req.root.villainActions.take(nextStage - 2).toList();
    return current.copyWith(board: board, villainActions: villain);
  }
}
