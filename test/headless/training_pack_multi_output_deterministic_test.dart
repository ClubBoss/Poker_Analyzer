import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/services/training_pack_auto_generator.dart';

void main() {
  test('multi-output expansion is deterministic', () async {
    final path = 'assets/training/templates/test_multi_output.yaml';
    final yaml = await File(path).readAsString();
    final set = TrainingPackTemplateSet.fromYaml(yaml, source: path);
    final gen = TrainingPackAutoGenerator();

    final packsA = await gen.generateAll(set, deduplicate: false);
    final packsB = await gen.generateAll(set, deduplicate: false);

    expect(packsA.length, packsB.length);
    for (var i = 0; i < packsA.length; i++) {
      final a = packsA[i];
      final b = packsB[i];
      expect(a.spots.length, b.spots.length);
      final idsA = [for (final s in a.spots) s.id];
      final idsB = [for (final s in b.spots) s.id];
      expect(idsA, idsB);
      final jsonA = jsonEncode([for (final s in a.spots) s.toJson()]);
      final jsonB = jsonEncode([for (final s in b.spots) s.toJson()]);
      final hashA = sha1.convert(utf8.encode(jsonA)).toString();
      final hashB = sha1.convert(utf8.encode(jsonB)).toString();
      expect(hashA, hashB);
      final yamlA = a.toYamlString();
      final yamlB = b.toYamlString();
      String norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
      expect(norm(yamlA), norm(yamlB));
      // Street assertion based on variant order
      final street = i == 0 ? 1 : 2;
      expect(a.spots.every((s) => s.street == street), isTrue);
      expect(b.spots.every((s) => s.street == street), isTrue);
    }
  });
}
