import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_preset.dart';

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
      bbCallPct: 100,
    );
    expect(tpl.spots.length, 20);
    final ids = <String>{};
    for (final s in tpl.spots) {
      expect(ids.add(s.id), isTrue);
      expect(s.title.endsWith('push'), isTrue);
      expect(s.hand.heroCards.isNotEmpty, isTrue);
      expect(s.hand.actions[0]?.first.action, 'push');
      expect(s.hand.actions[0]?.length, 2);
      expect(s.tags.contains('pushfold'), isTrue);
    }
  });

  test('bb calls with top hands', () async {
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 'c',
      name: 'Call',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: ['AA'],
      bbCallPct: 100,
    );
    expect(tpl.spots.first.hand.actions[0]?[1].action, 'call');
  });

  test('bb calls with top hands at 20 pct', () async {
    final tpl = PackGeneratorService.generatePushFoldPackSync(
      id: 'c2',
      name: 'Call20',
      heroBbStack: 10,
      playerStacksBb: [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: ['AA'],
      bbCallPct: 20,
    );
    expect(tpl.spots.first.hand.actions[0]?[1].action, 'call');
  });

  test('parseRangeString and serializeRange are idempotent', () {
    const raw = 'A2s 22 KQo';
    final parsed = PackGeneratorService.parseRangeString(raw);
    final serialized = PackGeneratorService.serializeRange(parsed);
    expect(PackGeneratorService.parseRangeString(serialized), parsed);
  });

  test('generateFinalTablePack creates correct spots', () {
    final tpl = PackGeneratorService.generateFinalTablePack();
    final count = PackGeneratorService.topNHands(10).length;
    expect(tpl.spots.length, count);
    for (final s in tpl.spots) {
      expect(s.hand.heroIndex, 3);
      expect(s.hand.position, HeroPosition.co);
      expect(s.hand.playerCount, 9);
      expect(s.hand.stacks['3'], 30);
      expect(s.hand.actions[0]?.first.action, 'push');
      expect(s.hand.actions[0]?.length, 9);
      expect(s.tags.contains('finaltable'), isTrue);
    }
  });

  test('autoGenerateSpots returns expected count', () async {
    final spots = await PackGeneratorService.autoGenerateSpots(
      id: 'a',
      stack: 10,
      players: [10, 10],
      pos: HeroPosition.sb,
      count: 5,
    );
    expect(spots.length, 5);
    for (final s in spots) {
      expect(s.hand.stacks, {'0': 10.0, '1': 10.0});
      expect(s.tags.contains('pushfold'), isTrue);
    }
  });

  test('generatePackFromPreset builds template', () async {
    final preset = TrainingPackPreset(
      id: 'pr',
      name: 'Preset',
      description: 'd',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: const ['AA'],
      spotCount: 1,
    );
    final tpl = await PackGeneratorService.generatePackFromPreset(preset);
    expect(tpl.id, preset.id);
    expect(tpl.name, preset.name);
    expect(tpl.description, preset.description);
    expect(tpl.spots.length, 1);
    expect(tpl.heroRange, preset.heroRange);
  });
}
