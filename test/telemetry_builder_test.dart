import 'package:test/test.dart';
import 'package:poker_analyzer/infra/telemetry_builder.dart';

void main() {
  group('buildTelemetry', () {
    test('adds sessionId and data', () {
      final r = buildTelemetry(sessionId: 's1', data: {'a': 1});
      expect(r, {'sessionId': 's1', 'a': 1});
      expect(r.containsKey('packId'), isFalse);
    });

    test('includes packId when provided', () {
      final r = buildTelemetry(sessionId: 's1', packId: 'p1', data: {'b': 'x'});
      expect(r, {'sessionId': 's1', 'packId': 'p1', 'b': 'x'});
    });

    test('ignores overrides for sessionId and packId', () {
      final r = buildTelemetry(
        sessionId: 's1',
        packId: 'p1',
        data: {'sessionId': 'z', 'packId': 'y', 'c': 2},
      );
      expect(r, {'sessionId': 's1', 'packId': 'p1', 'c': 2});
    });

    test('drops non-ascii keys', () {
      final r = buildTelemetry(sessionId: 's1', data: {'ключ': 1, 'a': 2});
      expect(r, {'sessionId': 's1', 'a': 2});
      for (final k in r.keys) {
        expect(k.codeUnits.every((c) => c < 128), isTrue);
      }
    });
  });
}
