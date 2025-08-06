import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/board_texture_tag.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';

void main() {
  final classifier = BoardTextureClassifier();

  test('classifies paired ace-high board as wet', () {
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: 'A', suit: 'h'),
      CardModel(rank: 'T', suit: 'd'),
    ];
    final tags = classifier.classify(board);
    expect(tags.contains(BoardTextureTag.paired), isTrue);
    expect(tags.contains(BoardTextureTag.aceHigh), isTrue);
    expect(tags.contains(BoardTextureTag.wet), isTrue);
  });

  test('classifies monotone low straighty board', () {
    final board = [
      CardModel(rank: '2', suit: 'c'),
      CardModel(rank: '3', suit: 'c'),
      CardModel(rank: '4', suit: 'c'),
    ];
    final tags = classifier.classify(board);
    expect(tags.containsAll({
      BoardTextureTag.low,
      BoardTextureTag.monotone,
      BoardTextureTag.straighty,
      BoardTextureTag.wet,
    }), isTrue);
    expect(tags.contains(BoardTextureTag.dry), isFalse);
  });

  test('classifies rainbow ace-high dry board', () {
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: 'K', suit: 'd'),
      CardModel(rank: '7', suit: 'h'),
    ];
    final tags = classifier.classify(board);
    expect(tags.containsAll({
      BoardTextureTag.aceHigh,
      BoardTextureTag.high,
      BoardTextureTag.rainbow,
      BoardTextureTag.disconnected,
      BoardTextureTag.dry,
    }), isTrue);
    expect(tags.contains(BoardTextureTag.wet), isFalse);
  });
}
