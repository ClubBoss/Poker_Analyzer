import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/schema_check.dart';

void main() {
  test('detects non-map outputVariants', () {
    final yaml = loadYaml('baseSpot: {}\noutputVariants: []');
    final errors = validateMap(yaml as Map, source: 'test');
    expect(errors.any((e) => e.startsWith('E_OUTPUT_VARIANTS_MAP_REQUIRED')),
        isTrue);
  });

  test('passes valid template', () {
    const src = '''
baseSpot: {}
outputVariants:
  good:
    targetStreet: flop
    requiredTags: [a, b]
    excludedTags: []
    boardConstraints:
      - {}
    seed: 1
''';
    final yaml = loadYaml(src);
    final errors = validateMap(yaml as Map, source: 'valid');
    expect(errors, isEmpty);
  });
}
