import 'package:test/test.dart';
import '../tooling/content_audit.dart';

void main() {
  test('demo validator passes', () {
    final res = validateDemoLine({
      'id': 'm1:demo:01',
      'title': 't',
      'steps': ['a']
    }, 'm1');
    expect(res.isValid, isTrue);
    expect(res.badIdPattern, isFalse);
  });

  test('drill validator passes', () {
    final res = validateDrillLine({
      'id': 'm1:drill:01',
      'spotKind': 'kind',
      'params': {},
      'target': ['a'],
      'rationale': 'because'
    }, 'm1');
    expect(res.isValid, isTrue);
    expect(res.badIdPattern, isFalse);
  });

  test('isAscii', () {
    expect(isAscii('abc'), isTrue);
    expect(isAscii('á'), isFalse);
  });
}

