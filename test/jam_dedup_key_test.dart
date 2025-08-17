import 'package:test/test.dart';

import '../lib/ui/session_player/spot_specs.dart';
import '../lib/ui/session_player/models.dart';
import '../lib/services/spot_importer.dart';

UiSpot _spot(String json) =>
    SpotImporter.parse(json, format: 'json').spots.single;

void main() {
  group('jamDedupKey', () {
    test('Equal', () {
      const j =
          '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"SB","stack":"20bb","action":"jam"}';
      final a = _spot(j);
      final b = _spot(j);
      expect(jamDedupKey(a), jamDedupKey(b));
    });

    test('Different fields', () {
      final base = _spot(
          '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"SB","stack":"20bb","action":"jam"}');
      final variants = [
        _spot(
            '{"kind":"l3_turn_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"SB","stack":"20bb","action":"jam"}'),
        _spot(
            '{"kind":"l3_flop_jam_vs_raise","hand":"AQs","pos":"BTN","vsPos":"SB","stack":"20bb","action":"jam"}'),
        _spot(
            '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"CO","vsPos":"SB","stack":"20bb","action":"jam"}'),
        _spot(
            '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"BB","stack":"20bb","action":"jam"}'),
        _spot(
            '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"SB","stack":"25bb","action":"jam"}'),
      ];
      for (final v in variants) {
        expect(jamDedupKey(base), isNot(equals(jamDedupKey(v))));
      }
    });

    test('vsPos null vs empty', () {
      final a = _spot(
          '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","stack":"20bb","action":"jam"}');
      final b = _spot(
          '{"kind":"l3_flop_jam_vs_raise","hand":"AKs","pos":"BTN","vsPos":"","stack":"20bb","action":"jam"}');
      expect(jamDedupKey(a), jamDedupKey(b));
    });
  });
}
