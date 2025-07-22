import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_loss_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detect flags degrading skills sorted by drop', () {
    final detector = const SkillLossDetector();
    final history = {
      'a': [0.8, 0.7, 0.6],
      'b': [0.5, 0.6, 0.7],
      'c': [0.9, 0.95, 0.8],
      'd': [0.9, 0.9],
    };
    final res = detector.detect(history);
    expect(res.length, 2);
    expect(res[0].tag, 'a');
    expect(res[0].trend, 'Steady decline');
    expect(res[1].tag, 'c');
    expect(res[1].trend, 'Recent collapse');
  });
}
