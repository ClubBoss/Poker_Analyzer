import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/theory_recap_trigger_logger.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs events and retrieves recent list', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    await TheoryRecapTriggerLogger.logPrompt('l1', 'weakness', 'accepted');
    await TheoryRecapTriggerLogger.logPrompt('l2', 'booster', 'dismissed');

    final file = File('${dir.path}/app_data/recap_prompt_log.json');
    expect(await file.exists(), true);
    final data = jsonDecode(await file.readAsString()) as List;
    expect(data.length, 2);

    final events = await TheoryRecapTriggerLogger.getRecentEvents();
    expect(events.length, 2);
    expect(events.first.lessonId, 'l2');
    expect(events.first.outcome, 'dismissed');

    await dir.delete(recursive: true);
  });
}
