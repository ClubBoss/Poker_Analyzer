import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  const enumPath = 'lib/ui/session_player/models.dart';

  late final String src;
  late final List<String> parsedNames;
  late final bool trailingComma;

  setUpAll(() {
    src = File(enumPath).readAsStringSync();
    // Extract enum SpotKind { ... }
    final re = RegExp(r'enum\s+SpotKind\s*\{([\s\S]*?)\}', dotAll: true);
    final match = re.firstMatch(src);
    if (match == null) {
      fail('SpotKind enum block not found. Verify path: $enumPath');
    }
    final body = match.group(1)!; // inside braces
    trailingComma = body.trimRight().endsWith(',');

    // Parse identifiers in declared order (strip comments, whitespace)
    parsedNames = <String>[];
    for (final raw in body.split(',')) {
      var t = raw.split('//').first.trim();
      if (t.isEmpty) continue;
      final m = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)\s*$').firstMatch(t);
      if (m != null) {
        parsedNames.add(m.group(1)!);
      }
    }
  });

  test('order is append-only: runtime equals source order', () {
    final runtimeNames = SpotKind.values.map((e) => e.name).toList();
    expect(
      runtimeNames,
      parsedNames,
      reason:
          'SpotKind must be append-only: do not rename/reorder; only append at the end (with trailing comma).',
    );
  });

  test('all names are unique', () {
    expect(
      parsedNames.toSet().length,
      parsedNames.length,
      reason: 'Duplicate SpotKind identifiers found.',
    );
  });

  test('last enumerator ends with a trailing comma', () {
    expect(
      trailingComma,
      isTrue,
      reason:
          'The last SpotKind enumerator must end with a comma before the closing }. This enforces append-only diffs.',
    );
  });
}
