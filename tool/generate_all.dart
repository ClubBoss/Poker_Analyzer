import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/utils/yaml_utils.dart';

Future<void> main() async {
  final dir = Directory('tool/example_spots');
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: tool/example_spots');
    exit(1);
  }
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList();
  stdout.writeln('Generating ${files.length} packs...');
  final start = DateTime.now();
  var index = 0;
  var errors = 0;
  for (final file in files) {
    index++;
    final name = p.basenameWithoutExtension(file.path);
    final res = await Process.run('dart', [
      'run',
      'tool/generate_pack.dart',
      '--input=${file.path}',
      '--output=$name.yaml'
    ]);
    var ok = res.exitCode == 0;
    if (ok) {
      final out = File(p.join('assets', 'packs', '$name.yaml'));
      try {
        final doc = loadYaml(out.readAsStringSync());
        final map = yamlToDart(doc) as Map<String, dynamic>;
        final tpl = TrainingPackTemplate.fromJson(map);
        final issues = validateTrainingPackTemplate(tpl);
        if (issues.isNotEmpty) {
          ok = false;
          stderr.writeln(issues.join('; '));
        }
      } catch (e) {
        ok = false;
        stderr.writeln(e.toString());
      }
    }
    stdout.writeln(
        '[$index/${files.length}] $name.yaml  -  ${ok ? 'OK' : '[ERROR]'}');
    if (!ok) {
      errors++;
      stderr.write(res.stdout);
      stderr.write(res.stderr);
    }
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
  stdout.writeln('Generated ${files.length - errors} of ${files.length} packs');
  if (errors > 0) exit(1);
}
