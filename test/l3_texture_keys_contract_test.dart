import 'dart:convert';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_presets.dart';
import 'package:poker_analyzer/services/autogen_stats.dart';
import 'package:poker_analyzer/services/autogen_v4.dart';
import 'package:poker_analyzer/services/texture_keys.dart';
import 'package:poker_analyzer/utils/board_textures.dart';

void main() {
  test('preset keys match canonical keys', () {
    final keys = kAutogenPresets['postflop_default']!.targetMix.keys.toSet();
    expect(keys, kTextureKeySet);
  });

  test('generated textures use canonical keys', () {
    final gen = BoardStreetGenerator(seed: 7);
    final spots = gen.generate(count: 200, preset: 'postflop_default');
    for (final spot in spots) {
      final board = (spot['board'] as List).cast<String>();
      final textures = classifyFlop(board);
      for (final tex in textures) {
        expect(kTextureKeySet.contains(tex.name), isTrue);
      }
    }
  });

  test('buildAutogenStats textures subset canonical keys', () {
    final gen = BoardStreetGenerator(seed: 7);
    final spots = gen.generate(count: 200, preset: 'postflop_default');
    final report = jsonEncode({'spots': spots});
    final stats = buildAutogenStats(report);
    expect(stats, isNotNull);
    expect(stats!.textures.keys.toSet().difference(kTextureKeySet), isEmpty);
  });
}
