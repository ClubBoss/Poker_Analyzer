import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/services/icm_push_ev_service.dart';

void main() {
  test('icm ev positive for strong hand', () {
    final ev = computeIcmPushEV(
      chipStacksBb: [30, 20, 10],
      heroIndex: 0,
      heroHand: 'AA',
      chipPushEv: 1.5,
    );
    expect(ev, greaterThan(0));
  });

  test('icm ev negative for weak hand', () {
    final ev = computeIcmPushEV(
      chipStacksBb: [30, 20, 10],
      heroIndex: 0,
      heroHand: '72o',
      chipPushEv: -1.0,
    );
    expect(ev, lessThan(0));
  });
}
