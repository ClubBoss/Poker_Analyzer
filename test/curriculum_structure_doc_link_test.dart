import 'dart:io';

import 'package:test/test.dart';

bool _isAscii(String s) => s.codeUnits.every((c) => c <= 0x7F);

void main() {
  test('CURRICULUM_STRUCTURE.md links to RICH_TRACK_SCHEMA', () async {
    final file = File('CURRICULUM_STRUCTURE.md');
    expect(
      await file.exists(),
      isTrue,
      reason: 'CURRICULUM_STRUCTURE.md not found at repo root',
    );

    final content = await file.readAsString();

    // Guard: link substring must exist
    const link = 'docs/RICH_TRACK_SCHEMA.md';
    expect(
      content.contains(link),
      isTrue,
      reason:
          'Missing link to docs/RICH_TRACK_SCHEMA.md in CURRICULUM_STRUCTURE.md',
    );

    // Guard: the added section lines should be ASCII-only
    const summaryLine =
        'Units of 6 modules; packs L1/L2/BRIDGE/CHECKPOINT/BOSS; IDs are append-only.';
    expect(
      content.contains(summaryLine),
      isTrue,
      reason: 'Missing Rich Track summary line in CURRICULUM_STRUCTURE.md',
    );

    // Verify ASCII for the link line and the summary line specifically.
    expect(
      _isAscii(link),
      isTrue,
      reason: 'Non-ASCII bytes found in the link literal',
    );
    expect(
      _isAscii(summaryLine),
      isTrue,
      reason: 'Non-ASCII bytes found in the Rich Track summary line',
    );
  });
}
