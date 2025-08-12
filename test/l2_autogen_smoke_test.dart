import 'dart:io';

import 'package:test/test.dart';

import '../tool/autogen/l2_presets.dart';

void main() {
  const seeds = ['111', '222', '333'];

  for (final preset in allPresets) {
    test('preset ' + preset, () async {
      for (final seed in seeds) {
        final outDir = 'build/tmp/l2_test/$preset/$seed';
        final gen = await Process.run(
          'dart',
          [
            'run',
            'tool/autogen/l2_pack_generator.dart',
            '--preset',
            preset,
            '--seed',
            seed,
            '--out',
            outDir,
          ],
        );
        expect(gen.exitCode, 0, reason: gen.stderr.toString());
        final val = await Process.run(
          'dart',
          [
            'run',
            'tool/validators/preset_validator.dart',
            '--dir',
            outDir,
          ],
        );
        expect(val.exitCode, 0, reason: val.stderr.toString());
      }
    });
  }
}
