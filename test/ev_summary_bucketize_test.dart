import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/widgets/ev_summary_card.dart';

void main() {
  test('bucketize count', () {
    final vals = [1.0, -0.5, 0.2, 4.0];
    final bins = bucketize(vals, 10);
    expect(bins.length, 10);
    expect(bins.reduce((a, b) => a + b), vals.length);
  });
}
