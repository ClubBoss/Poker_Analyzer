import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_preset.dart';

void main() {
  test('batch generate presets', () async {
    final dir = await Directory.systemTemp.createTemp('batch_generate_test');
    try {
      final p1 = TrainingPackPreset(id: 'a', name: 'A');
      final p2 = TrainingPackPreset(id: 'b', name: 'B');
      await File(
        p.join(dir.path, 'presets.json'),
      ).writeAsString(jsonEncode([p1.toJson(), p2.toJson()]));
      final res = await Process.run('dart', [
        'run',
        'bin/batch_generate.dart',
        '--src',
        p.join(dir.path, 'presets.json'),
        '--out',
        dir.path,
      ]);
      expect(res.exitCode, 0);
      expect(File(p.join(dir.path, 'a.json')).existsSync(), isTrue);
      expect(File(p.join(dir.path, 'b.json')).existsSync(), isTrue);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
