import 'package:poker_analyzer/core/autogen/texture_filter_engine.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';
import 'package:test/test.dart';

void main() {
  final engine = TextureFilterEngine();
  final classifier = const BoardTextureClassifier();

  test('include/exclude', () {
    final spots = ['KsQsJs', '2c3d5h', 'AhAd7s'];
    final filtered = engine.filter<String>(
      spots,
      (s) => s,
      {'monotone', 'rainbow'},
      {'paired'},
      {'monotone': 0.5, 'rainbow': 0.5},
      classifier: classifier,
    );
    expect(filtered, ['KsQsJs', '2c3d5h']);
  });

  test('target mix enforcement with tolerance', () {
    final spots = ['KsQsJs', 'AsKsQs', 'AhKhQh', '2c3d5h', '4c5d6h'];
    final rejects = <String>[];
    final result = engine.filter<String>(
      spots,
      (s) => s,
      {},
      {},
      {'monotone': 0.5, 'rainbow': 0.5},
      spotsPerPack: 4,
      tolerance: 0,
      classifier: classifier,
      onReject: rejects.add,
    );
    expect(result, ['KsQsJs', 'AsKsQs', '2c3d5h', '4c5d6h']);
    expect(rejects, contains('monotone'));
  });

  test('twoTone detection', () {
    final spots = ['AhAd7s', '2c3d5h'];
    final filtered = engine.filter<String>(
      spots,
      (s) => s,
      {'twoTone'},
      {},
      {},
      classifier: classifier,
    );
    expect(filtered, ['AhAd7s']);
  });
}
