import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/services/pack_generator_service.dart';

void main() {
  test('topNHands returns approx count', () {
    final top = PackGeneratorService.topNHands(20);
    expect(top.length, 34);
  });
}
