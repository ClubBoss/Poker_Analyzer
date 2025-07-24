import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/smart_path_compiler.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('compiler_test');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('compile returns yaml for valid packs', () {
    File('${dir.path}/s1_main.yaml').writeAsStringSync('');
    File('${dir.path}/s2_main.yaml').writeAsStringSync('');

    final compiler = SmartPathCompiler();
    final yaml = compiler.compile(['s1:A,B', 's2:A'], dir);

    final map = const YamlReader().read(yaml);
    final stages = map['stages'] as List? ?? [];
    expect(stages.length, 2);
    expect(stages.first['id'], 's1');
  });

  test('compile throws when pack missing', () {
    File('${dir.path}/s1_main.yaml').writeAsStringSync('');

    final compiler = SmartPathCompiler();
    expect(() => compiler.compile(['s1:A', 's2:A'], dir), throwsException);
  });
}
