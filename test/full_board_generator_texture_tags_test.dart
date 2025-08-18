import 'dart:math';
import 'package:test/test.dart';
import 'package:poker_analyzer/services/full_board_generator.dart';
import 'package:poker_analyzer/services/board_filtering_service_v2.dart';
import 'package:poker_analyzer/models/board_stages.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';
import 'package:poker_analyzer/models/card_model.dart';

class _CountingClassifier extends BoardTextureClassifier {
  int calls = 0;
  @override
  Set<String> classifyCards(List<CardModel> board) {
    calls++;
    return super.classifyCards(board);
  }
}

void main() {
  test('generated boards include texture tags and YAML export', () {
    final classifier = _CountingClassifier();
    final generator = FullBoardGenerator(
      random: Random(1),
      classifier: classifier,
    );
    final board = generator.generate(
      boardConstraints: {'paired': true, 'aceHigh': true},
    );
    expect(board.textureTags.containsAll({'paired', 'aceHigh'}), isTrue);

    final yaml = board.toYAML();
    expect(yaml, contains('tags:'));

    final stages = BoardStages(
      flop: board.flop.map((c) => c.toString()).toList(),
      turn: board.turn!.toString(),
      river: board.river!.toString(),
      textureTags: board.textureTags,
    );
    final filter = BoardFilteringServiceV2();
    expect(filter.isMatch(stages, {'paired'}), isTrue);
    expect(classifier.calls, 1);
  });
}
