@Tags(['flutter'])
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('plugin scaffold', () async {
    final dir = await Directory.systemTemp.createTemp('plugin_scaffold_test');
    const pluginName = 'MyPlugin';
    try {
      final script = File('tools/plugin_scaffold.dart');
      await script.copy(p.join(dir.path, 'plugin_scaffold.dart'));
      final errorSrc = File('lib/core/error_logger.dart');
      final errorDst =
          File(p.join(dir.path, 'lib', 'core', 'error_logger.dart'));
      await errorDst.create(recursive: true);
      await errorDst.writeAsString(await errorSrc.readAsString());
      await File(p.join(dir.path, 'pubspec.yaml')).writeAsString('''
name: poker_ai_analyzer
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  path: any
  flutter:
    sdk: flutter
''');
      final pub =
          await Process.run('dart', ['pub', 'get'], workingDirectory: dir.path);
      expect(pub.exitCode, 0);
      final res1 = await Process.run(
          'dart', ['run', 'plugin_scaffold.dart', pluginName],
          workingDirectory: dir.path);
      expect(res1.exitCode, 0);
      final output1 = '${res1.stdout}\n${res1.stderr}';
      expect(output1, contains('Created plugin'));
      final pluginFile = File(p.join(dir.path, 'plugins', '$pluginName.dart'));
      expect(pluginFile.existsSync(), isTrue);
      expect(pluginFile.readAsStringSync(),
          contains('class $pluginName implements Plugin'));
      final res2 = await Process.run(
          'dart', ['run', 'plugin_scaffold.dart', pluginName],
          workingDirectory: dir.path);
      expect(res2.exitCode, 0);
      final output = '${res2.stdout}\n${res2.stderr}';
      expect(output, contains('Plugin already exists'));
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
