import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/services/training_pack_auto_generator.dart';

void main() {
  test('generateAll produces multiple outputs', () async {
    final yaml = await File('assets/training/templates/test_multi_output.yaml').readAsString();
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final gen = TrainingPackAutoGenerator();
    final results = await gen.generateAll(set);
    expect(results.length, 2);
    expect(results[0].isNotEmpty, isTrue);
    expect(results[1].isNotEmpty, isTrue);
    // First variant should target flop (street 1)
    expect(results[0].every((s) => s.street == 1), isTrue);
    // Second variant should target turn (street 2)
    expect(results[1].every((s) => s.street == 2), isTrue);
  });
}
