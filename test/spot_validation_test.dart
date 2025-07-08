import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

void main() {
  test('missing hero cards reported', () {
    final spot = TrainingPackSpot(id: 's');
    final issues = validateSpot(spot, 0);
    expect(issues, isNotEmpty);
    expect(issues.first.message, contains('no hero cards'));
  });
}
