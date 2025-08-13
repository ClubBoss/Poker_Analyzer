import 'package:test/test.dart';
import 'package:poker_analyzer/helpers/title_utils.dart';

void main() {
  group('normalizeSpotTitle', () {
    test('formats title correctly', () {
      expect(normalizeSpotTitle('  hero bb vs sb  '), 'Hero BB vs SB');
      expect(normalizeSpotTitle('utg  vs  bb'), 'UTG vs BB');
    });
  });
}
