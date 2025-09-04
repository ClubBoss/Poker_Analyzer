import 'dart:io';

Future<int> _run(String label, List<String> args) async {
  final result = await Process.run('dart', args);
  final ok = result.exitCode == 0;
  stdout.writeln('${label}: ${ok ? 'PASS' : 'FAIL'}');
  return result.exitCode;
}

Future<void> main(List<String> args) async {
  final liveCode = await _run('FAST_LIVE', [
    'run',
    'tool/fast_live_check.dart',
  ]);
  final contentCode = await _run('FAST_CONTENT', [
    'run',
    'tool/fast_content_check.dart',
  ]);
  exit((liveCode == 0 && contentCode == 0) ? 0 : 1);
}
