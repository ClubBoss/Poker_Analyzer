import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateSpots returns expected spots', () async {
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      spotCount: 5,
      playerStacksBb: [10, 10],
    );
    final spots = await tpl.generateSpots();
    expect(spots.length, 5);
    for (final s in spots) {
      expect(s.hand.stacks, {'0': 10.0, '1': 10.0});
    }
  });
}
