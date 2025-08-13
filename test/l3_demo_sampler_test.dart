import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('l3 demo sampler produces valid packs', () async {
    final gen = await Process.run('dart', [
      'run',
      'tool/autogen/l3_board_generator.dart',
      '--preset',
      'all',
      '--seed',
      '111',
      '--out',
      'build/tmp/l3/111',
      '--maxAttemptsPerSpot',
      '5000',
      '--timeoutSec',
      '90',
    ]);
    if (gen.exitCode != 0) {
      fail('generator failed\nstdout: ${gen.stdout}\nstderr: ${gen.stderr}');
    }

    final sampler = await Process.run('dart', [
      'run',
      'tool/autogen/l3_demo_sampler.dart',
      '--source',
      'build/tmp/l3/111',
      '--preset',
      'all',
      '--out',
      'assets/packs/l3/demo',
      '--spots',
      '100',
      '--dedupe',
      'flop',
      '--seed',
      '111',
    ]);
    if (sampler.exitCode != 0) {
      fail(
          'sampler failed\nstdout: ${sampler.stdout}\nstderr: ${sampler.stderr}');
    }

    final validator = await Process.run('dart', [
      'run',
      'tool/validators/l3_demo_validator.dart',
      '--dir',
      'assets/packs/l3/demo',
      '--dedupe',
      'flop',
    ]);
    if (validator.exitCode != 0) {
      fail(
          'validator failed\nstdout: ${validator.stdout}\nstderr: ${validator.stderr}');
    }

    final dir = Directory('assets/packs/l3/demo');
    final files =
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final content = loadYaml(file.readAsStringSync()) as Map;
      final spots = List.from(content['spots'] as List? ?? []);
      expect(spots.length >= 80, true, reason: 'insufficient spots');
      for (final spot in spots) {
        final tags = List.from((spot as Map)['tags'] as List? ?? []);
        final hasTexture = tags.contains('monotone') ||
            tags.contains('twoTone') ||
            tags.contains('rainbow');
        expect(hasTexture, true, reason: 'missing texture tag');
      }
    }
  });
}
