import 'dart:io';
import 'package:test/test.dart';

void main() {
  final src = File('lib/ui/session_player/mvs_player.dart').readAsStringSync();
  const kinds = [
    'l3_flop_jam_vs_raise',
    'l3_turn_jam_vs_raise',
    'l3_river_jam_vs_raise',
    'l4_icm_bubble_jam_vs_fold',
    'l4_icm_ladder_jam_vs_fold',
    'l4_icm_sb_jam_vs_fold',
  ];
  test('_autoReplayKinds enums', () {
    final m = RegExp(r'const _autoReplayKinds = {([^}]+)};').firstMatch(src)!;
    final found = RegExp(r'SpotKind\.(\w+)')
        .allMatches(m.group(1)!)
        .map((e) => e.group(1)!)
        .toList();
    expect(found, kinds);
  });
  test('_actionsFor jam/fold', () {
    for (final k in kinds) {
      expect(
          RegExp("case SpotKind\\.$k:\\n\\s+return \\[\'jam\', \'fold\'\\];")
              .hasMatch(src),
          true);
    }
  });
  test('subtitle prefixes', () {
    const pref = {
      'l3_flop_jam_vs_raise': 'Flop Jam vs Raise •',
      'l3_turn_jam_vs_raise': 'Turn Jam vs Raise •',
      'l3_river_jam_vs_raise': 'River Jam vs Raise •',
      'l4_icm_bubble_jam_vs_fold': 'ICM Bubble Jam vs Fold •',
      'l4_icm_ladder_jam_vs_fold': 'ICM FT Ladder Jam vs Fold •',
      'l4_icm_sb_jam_vs_fold': 'ICM SB Jam vs Fold •',
    };
    pref.forEach((k, p) => expect(src.contains(p), true));
  });
}
