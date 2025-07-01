import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/services/pack_generator_service.dart';
import 'package:poker_ai_analyzer/models/v2/hero_position.dart';

void main() {
  test('generatePushFoldPack creates correct spots', () async {
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 't',
      name: 'Test',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: [
        '22',
        '33',
        'A2s',
        'A3s',
        'K9s',
        'Q9s',
        'J9s',
        'T9s',
        '98s',
        'AJo',
        'KQo',
        'A2o',
        'A3o',
        'A4o',
        'A5o',
        'A6o',
        'A7o',
        'A8o',
        'A9o',
        'ATo',
      ],
    );
    expect(tpl.spots.length, 20);
    final ids = <String>{};
    for (final s in tpl.spots) {
      expect(ids.add(s.id), isTrue);
      expect(s.title.endsWith('push'), isTrue);
      expect(s.hand.heroCards.isNotEmpty, isTrue);
      expect(s.hand.actions[0]?.first.action, 'push');
      expect(s.hand.actions[0]?.length, 2);
    }
  });
}
