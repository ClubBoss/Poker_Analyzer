import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';

void main() {
  test('AA push EV positive', () {
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: 'AA',
      anteBb: 0,
    );
    expect(ev, greaterThan(8));
  });

  test('72o push EV negative', () {
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: '72o',
      anteBb: 0,
    );
    expect(ev, lessThan(-2));
  });

  test('AA push EV positive with ante', () {
    final ev = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: 'AA',
      anteBb: 1,
    );
    expect(ev, greaterThan(9));
  });
}
