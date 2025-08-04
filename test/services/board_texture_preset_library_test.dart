import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_preset_library.dart';

void main() {
  test('returns preset map for lowPaired', () {
    final preset = BoardTexturePresetLibrary.get('lowPaired');
    expect(preset['requiredTextures'], ['paired', 'low', 'rainbow']);
  });

  test('throws on unknown preset', () {
    expect(() => BoardTexturePresetLibrary.get('unknown'), throwsArgumentError);
  });
}
