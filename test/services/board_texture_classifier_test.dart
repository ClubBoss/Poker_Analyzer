import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_classifier.dart';

void main() {
  final classifier = const BoardTextureClassifier();

  test('classifies paired ace-high board as wet', () {
    final tags = classifier.classify('AsAhTd');
    expect(tags.contains('paired'), isTrue);
    expect(tags.contains('aceHigh'), isTrue);
    expect(tags.contains('wet'), isTrue);
  });

  test('detects two pairs on turn', () {
    final tags = classifier.classify('AsAhKdKc');
    expect(tags.contains('twoPaired'), isTrue);
    expect(tags.contains('paired'), isTrue);
    expect(tags.contains('trip'), isFalse);
  });

  test('detects trips', () {
    final tags = classifier.classify('AsAhAc');
    expect(tags.contains('trip'), isTrue);
    expect(tags.contains('paired'), isTrue);
  });

  test('detects flush draw on turn', () {
    final tags = classifier.classify('AsKsQd2s');
    expect(tags.contains('flushDraw'), isTrue);
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
      tags.containsAll({'aceHigh', 'high', 'rainbow', 'disconnected', 'dry'}),
      isTrue,
    );
    expect(tags.contains('wet'), isFalse);
  });

  test('detects straight draw', () {
    final tags = classifier.classify('4c5d8h');
    expect(tags.contains('straightDraw'), isTrue);
    expect(tags.contains('wet'), isTrue);
  });

  test('detects broadway board', () {
    final tags = classifier.classify('AsKsQh');
    expect(tags.contains('broadway'), isTrue);
    expect(tags.contains('high'), isTrue);
    expect(tags.contains('aceHigh'), isTrue);
  });
}
