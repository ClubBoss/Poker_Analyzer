import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_preset_library.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  test('returns preset map for lowPaired', () {
    final preset = BoardTexturePresetLibrary.get('lowPaired');
    expect(preset['requiredTextures'], ['paired', 'low', 'rainbow']);
  });

  test('throws on unknown preset', () {
    expect(() => BoardTexturePresetLibrary.get('unknown'), throwsArgumentError);
  });

  test('matches returns true for compatible board', () {
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: '9', suit: 'd'),
      CardModel(rank: '4', suit: 'c'),
    ];
    expect(BoardTexturePresetLibrary.matches(board, 'dryAceHigh'), isTrue);
  });

  test('matches returns false for incompatible board', () {
    final board = [
      CardModel(rank: '7', suit: 'h'),
      CardModel(rank: '7', suit: 'd'),
      CardModel(rank: '2', suit: 'c'),
    ];
    expect(BoardTexturePresetLibrary.matches(board, 'dryAceHigh'), isFalse);
  });
}
