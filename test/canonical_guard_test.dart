import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('canonical guard marker or wiring must be present (lib only)', () {
    const literal =
        '!correct&&autoWhy&&(spot.kind==SpotKind.l3_flop_jam_vs_raise||spot.kind==SpotKind.l3_turn_jam_vs_raise||spot.kind==SpotKind.l3_river_jam_vs_raise)&&!_replayed.contains(spot)';
    const markerPrefix = '// CANONICAL_GUARD:';

    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory is missing');

    final markerHits = <String>[]; // path:line:text
    var hasVar = false;
    var hasOrUse = false;

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isAscii = line.codeUnits.every((c) => c <= 0x7F);
        if (!isAscii) continue;

        if (line.startsWith(markerPrefix) && line.contains(literal)) {
          markerHits.add('${entity.path}:${i + 1}:$line');
        }
        if (!hasVar && line.contains('_canonicalAutoReplay')) {
          hasVar = true;
        }
        if (!hasOrUse && line.contains('|| _canonicalAutoReplay')) {
          hasOrUse = true;
        }
      }
    }

    if (markerHits.length > 1) {
      final buf = StringBuffer();
      buf.writeln(
        'Expected exactly 1 CANONICAL_GUARD marker; found ${markerHits.length}.',
      );
      for (final h in markerHits) {
        buf.writeln(h);
      }
      fail(buf.toString());
    }

    if (!hasVar || !hasOrUse) {
      final missing = [
        if (!hasVar) "'_canonicalAutoReplay'",
        if (!hasOrUse) "'|| _canonicalAutoReplay'",
      ].join(', ');
      fail('Missing required wiring token(s): $missing under lib/.');
    }

    if (markerHits.isEmpty) {
      return; // accept wiring without marker
    }
  });
}
