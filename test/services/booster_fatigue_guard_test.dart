import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/booster_fatigue_guard.dart';
import 'package:poker_analyzer/services/theory_recap_trigger_logger.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects fatigue from dismiss counts', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    for (var i = 0; i < 3; i++) {
      await TheoryRecapTriggerLogger.logPrompt('l$i', 'weak', 'dismissed');
    }
    for (var i = 0; i < 7; i++) {
      await TheoryRecapTriggerLogger.logPrompt('a$i', 'weak', 'accepted');
    }
    expect(await BoosterFatigueGuard.instance.isFatigued(), true);
    await dir.delete(recursive: true);
  });

  test('detects fatigue from consecutive dismissals', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    await TheoryRecapTriggerLogger.logPrompt('l1', 'weak', 'accepted');
    await TheoryRecapTriggerLogger.logPrompt('l2', 'weak', 'dismissed');
    await TheoryRecapTriggerLogger.logPrompt('l3', 'weak', 'dismissed');
    expect(await BoosterFatigueGuard.instance.isFatigued(), true);
    await dir.delete(recursive: true);
  });

  test('not fatigued with few dismissals', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    await TheoryRecapTriggerLogger.logPrompt('l1', 'weak', 'accepted');
    await TheoryRecapTriggerLogger.logPrompt('l2', 'weak', 'dismissed');
    await TheoryRecapTriggerLogger.logPrompt('l3', 'weak', 'accepted');
    expect(await BoosterFatigueGuard.instance.isFatigued(), false);
    await dir.delete(recursive: true);
  });
}
