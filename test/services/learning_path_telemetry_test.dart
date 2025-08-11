import 'dart:io';

import 'package:poker_analyzer/services/learning_path_telemetry.dart';
import 'package:poker_analyzer/services/analytics_adapter.dart';
import 'package:test/test.dart';

class _TestAdapter implements AnalyticsAdapter {
  int calls = 0;
  @override
  Future<void> send(String event, Map<String, Object?> data) async {
    calls++;
  }
}

void main() {
  test('log writes line and adapter called', () async {
    final dir = await Directory.systemTemp.createTemp('telemetry');
    final adapter = _TestAdapter();
    final t = LearningPathTelemetry.test(dir: dir);
    t.adapter = adapter;
    await t.log('e1', {'a': 1});
    await t.log('e2', {'a': 2});
    final file = File('${dir.path}/autogen_report.log');
    final lines = await file.readAsLines();
    expect(lines.length, 2);
    expect(adapter.calls, 2);
  });

  test('rotates when file exceeds limit', () async {
    final dir = await Directory.systemTemp.createTemp('telemetry');
    final t = LearningPathTelemetry.test(dir: dir, maxBytes: 200);
    final big = 'x' * 150;
    await t.log('e1', {'v': big});
    await t.log('e2', {'v': big});
    final f1 = File('${dir.path}/autogen_report.log.1');
    expect(await f1.exists(), true);
  });
}
