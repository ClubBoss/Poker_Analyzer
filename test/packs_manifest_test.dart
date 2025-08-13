import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('packs manifest generator', () async {
    final proc = await Process.run('dart', [
      'run',
      'tool/metrics/packs_manifest.dart',
      '--out',
      'build/reports/packs_manifest.json',
      '--mdOut',
      'build/reports/packs_manifest.md',
    ]);
    expect(proc.exitCode, 0, reason: 'generator failed');

    final file = File('build/reports/packs_manifest.json');
    expect(file.existsSync(), true, reason: 'manifest not found');
    final manifest = jsonDecode(await file.readAsString()) as Map;
    final packs = List.from(manifest['packs'] as List? ?? []);

    final demoIds = {'l3-demo-paired', 'l3-demo-unpaired', 'l3-demo-ace-high'};
    for (final id in demoIds) {
      final pack = packs.firstWhere((p) => p['id'] == id, orElse: () => null);
      expect(pack != null, true, reason: 'missing demo pack $id');
      final spotsCount = pack['spotsCount'] as int? ?? 0;
      expect(spotsCount >= 80, true, reason: 'insufficient spots for $id');
      final texture = Map<String, dynamic>.from(
        pack['textureHistogram'] as Map? ?? {},
      );
      for (final key in ['monotone', 'twoTone', 'rainbow']) {
        expect(texture.containsKey(key), true, reason: 'missing $key');
      }
    }

    // basic schema check
    for (final pack in packs) {
      expect(pack.containsKey('id'), true);
      expect(pack.containsKey('stage'), true);
      expect((pack['stage'] as Map).containsKey('id'), true);
      expect(pack.containsKey('subtype'), true);
      expect(pack.containsKey('street'), true);
      expect(pack.containsKey('file'), true);
      expect(pack.containsKey('spotsCount'), true);
      expect(pack.containsKey('tagsHistogram'), true);
      expect(pack.containsKey('textureHistogram'), true);
    }
  });
}
