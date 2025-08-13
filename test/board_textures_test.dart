import 'package:test/test.dart';
import 'package:poker_analyzer/utils/board_textures.dart';

void main() {
  test(
    'classifyFlop recognizes rainbow, aceHigh, broadwayHeavy',
    () {
      final res = classifyFlop(['Ah', 'Kd', '2c']);
      expect(res.contains(BoardTexture.rainbow), isTrue);
      expect(res.contains(BoardTexture.aceHigh), isTrue);
      expect(res.contains(BoardTexture.broadwayHeavy), isTrue);
    },
  );

  test(
    'classifyFlop handles twoTone, paired, broadwayHeavy with mixed ranks',
    () {
      final res = classifyFlop(['10h', 'Td', '2d']);
      expect(res.contains(BoardTexture.twoTone), isTrue);
      expect(res.contains(BoardTexture.paired), isTrue);
      expect(res.contains(BoardTexture.broadwayHeavy), isTrue);
    },
  );

  test(
    'classifyFlop detects monotone and lowConnected',
    () {
      final res = classifyFlop(['4c', '5c', '6c']);
      expect(res.contains(BoardTexture.monotone), isTrue);
      expect(res.contains(BoardTexture.lowConnected), isTrue);
    },
  );

  test(
    'parseBoard handles string boards with or without spaces',
    () {
      final board1 = parseBoard('AhKd2c');
      final board2 = parseBoard('Ah Kd 2c');
      expect(board1, ['Ah', 'Kd', '2c']);
      expect(board2, ['Ah', 'Kd', '2c']);
    },
  );
}
