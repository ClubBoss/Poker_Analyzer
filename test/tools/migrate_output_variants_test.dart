import 'package:test/test.dart';

import '../../tool/migrate_output_variants.dart' as migrator;

void main() {
  test('list form migrates to map with stable keys', () {
    const src = '''
baseSpot: {}
outputVariants:
  - targetStreet: flop
    requiredTags: [b, a]
  - key: X
    targetStreet: turn
''';
    final result = migrator.migrateOutputVariantsContent(src)!;
    expect(result.before, 2);
    expect(result.after, 2);
    expect(result.content, '''
baseSpot: {}
outputVariants:
  A:
    targetStreet: flop
    requiredTags:
      - a
      - b
  X:
    targetStreet: turn
''');
    final second = migrator.migrateOutputVariantsContent(result.content);
    expect(second, isNull);
  });
}
