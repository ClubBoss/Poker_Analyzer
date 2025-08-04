import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

void main() {
  test('toJson omits legacy fields and inlineLessonId', () {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(),
      inlineLessonId: 't1',
    );
    final json = spot.toJson();
    expect(json.containsKey('dirty'), false);
    expect(json.containsKey('image'), false);
    expect(json.containsKey('streetMode'), false);
    expect(json.containsKey('inlineLessonId'), false);

    final yaml = spot.toYaml();
    expect(yaml['inlineLessonId'], 't1');
  });
}
