import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../tool/schema_check.dart' as schema_check;

void main() {
  test('valid yaml passes', () {
    final map = loadYaml('''
baseSpot: {}
outputVariants:
  foo:
    targetStreet: flop
''') as Map;
    final err = schema_check.validateMap(map);
    expect(err, isNull);
  });

  test('non-map outputVariants rejected', () {
    final map = loadYaml('''
baseSpot: {}
outputVariants: []
''') as Map;
    final err = schema_check.validateMap(map);
    expect(err, isNotNull);
  });
}
