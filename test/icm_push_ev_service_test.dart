import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/icm_push_ev_service.dart';

void main() {
  test('icm ev positive for strong hand', () {
    final ev = computeLocalIcmPushEV(
      chipStacksBb: [30, 20, 10],
      heroIndex: 0,
      heroHand: 'AA',
      anteBb: 0,
    );
    expect(ev, greaterThan(0));
  });

  test('icm ev negative for weak hand', () {
    final ev = computeLocalIcmPushEV(
      chipStacksBb: [30, 20, 10],
      heroIndex: 0,
      heroHand: '72o',
      anteBb: 0,
    );
    expect(ev, lessThan(0));
  });
}
