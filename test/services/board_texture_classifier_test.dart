import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';

void main() {
  final classifier = BoardTextureClassifier();

  test('classifies paired ace-high board as wet', () {
    final tags = classifier.classify('AsAhTd');
    expect(tags.contains('paired'), isTrue);
    expect(tags.contains('aceHigh'), isTrue);
    expect(tags.contains('wet'), isTrue);
  });

  test('classifies monotone low connected board', () {
    final tags = classifier.classify('2c3c4c');
    expect(tags.containsAll({'low', 'monotone', 'connected', 'wet'}), isTrue);
    expect(tags.contains('dry'), isFalse);
  });

  test('classifies rainbow ace-high dry board', () {
    final tags = classifier.classify('AsKd7h');
    expect(
        tags.containsAll({
          'aceHigh',
          'high',
          'rainbow',
          'disconnected',
          'dry'
        }),
        isTrue);
    expect(tags.contains('wet'), isFalse);
  });
}
