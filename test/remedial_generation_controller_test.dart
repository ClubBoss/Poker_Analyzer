import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/stage_remedial_meta.dart';
import 'package:poker_analyzer/services/remedial_generation_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('dedupe logic respects age and accuracy improvement', () async {
    var runCalls = 0;
    Future<String> runAutogen({
      required String presetId,
      Map<String, dynamic>? extras,
      int? spotsPerPack,
    }) async {
      runCalls++;
      return 'gen$runCalls';
    }

    double currentAccuracy = 0.52;
    Future<double> fetchAcc(String _) async => currentAccuracy;

    final controller = RemedialGenerationController(
      autogenRunner: runAutogen,
      accuracyFetcher: fetchAcc,
    );

    final prefs = await SharedPreferences.getInstance();
    final meta = StageRemedialMeta(
      remedialPackId: 'existing',
      accuracyAfter: 0.5,
    );
    await prefs.setString(
        'learning.remedial.p.s', jsonEncode(meta.toJson()));

    final uri1 = await controller.createRemedialPack(
        pathId: 'p', stageId: 's');
    expect(runCalls, 0);
    expect(uri1.queryParameters['sideQuestId'], 'existing');

    currentAccuracy = 0.59; // +9pp improvement
    final uri2 = await controller.createRemedialPack(
        pathId: 'p', stageId: 's');
    expect(runCalls, 1);
    expect(uri2.queryParameters['sideQuestId'], 'gen1');

    final oldMeta = StageRemedialMeta(
      remedialPackId: 'old',
      accuracyAfter: 0.59,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    );
    await prefs.setString(
        'learning.remedial.p.s', jsonEncode(oldMeta.toJson()));

    currentAccuracy = 0.60; // <8pp but meta old
    final uri3 = await controller.createRemedialPack(
        pathId: 'p', stageId: 's');
    expect(runCalls, 2);
    expect(uri3.queryParameters['sideQuestId'], 'gen2');
  });

  test('returned uri contains all params', () async {
    Future<String> runAutogen({
      required String presetId,
      Map<String, dynamic>? extras,
      int? spotsPerPack,
    }) async => 'pack123';

    final controller = RemedialGenerationController(autogenRunner: runAutogen);
    final uri = await controller.createRemedialPack(
        pathId: 'path', stageId: 'stage');
    expect(uri.path, '/pathPlayer');
    expect(uri.queryParameters['pathId'], 'path');
    expect(uri.queryParameters['stageId'], 'stage');
    expect(uri.queryParameters['sideQuestId'], 'pack123');
  });
}
