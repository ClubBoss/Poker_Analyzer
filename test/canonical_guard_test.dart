import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String src;

  setUpAll(() {
    src = File('lib/ui/session_player/spot_specs.dart').readAsStringSync();
  });

  test('_autoReplayKinds contains exactly the three jam_vs_raise kinds', () {
    final re = RegExp(
      r'const\s+Set<SpotKind>\s+_autoReplayKinds\s*=\s*\{([^}]*)\}',
      dotAll: true,
    );
    final m = re.firstMatch(src);
    expect(m, isNotNull, reason: 'Missing _autoReplayKinds set');
    final inside = m!.group(1) ?? '';
    final entries = inside
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final expected = <String>{
      'SpotKind.l3_flop_jam_vs_raise',
      'SpotKind.l3_turn_jam_vs_raise',
      'SpotKind.l3_river_jam_vs_raise',
    };
    expect(
      entries.length,
      expected.length,
      reason: 'Unexpected number of kinds',
    );
    expect(
      entries.toSet(),
      expected,
      reason: 'Kinds mismatch in _autoReplayKinds',
    );
  });

  test('exactly one usage of _autoReplayKinds.contains', () {
    // Strip single-line comments before counting
    final codeOnly = src.replaceAll(RegExp(r'//.*', multiLine: true), '');
    final matches = RegExp(
      r'\b_autoReplayKinds\.contains\(',
    ).allMatches(codeOnly).length;
    expect(
      matches,
      1,
      reason:
          'There must be exactly one guard occurrence using _autoReplayKinds.contains(spot.kind)',
    );
  });

  test('canonical guard shape is correct', () {
    // Match: !correct && autoWhy && _autoReplayKinds.contains(spot.kind) && !_replayed.contains(spot)
    final codeOnly = src.replaceAll(RegExp(r'//.*', multiLine: true), '');
    final guardRe = RegExp(
      r'!\s*correct\s*&&\s*autoWhy\s*&&\s*_autoReplayKinds\.contains\(\s*spot\.kind\s*\)\s*&&\s*!\s*_replayed\.contains\(\s*spot\s*\)',
    );
    final count = guardRe.allMatches(codeOnly).length;
    expect(
      count,
      1,
      reason:
          'Canonical guard must appear exactly once with .contains(spot.kind)',
    );
  });
}
