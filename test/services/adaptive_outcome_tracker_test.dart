import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/adaptive_outcome_tracker.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';

InjectedPathModule _module(String id, List<String> tags) => InjectedPathModule(
  moduleId: id,
  clusterId: 'c$id',
  themeName: 't',
  theoryIds: const [],
  boosterPackIds: const [],
  assessmentPackId: 'a$id',
  createdAt: DateTime.now(),
  triggerReason: 'test',
  metrics: {'clusterTags': tags},
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('baseline and delta aggregation', () async {
    final tracker = AdaptiveOutcomeTracker.instance;
    final m1 = _module('m1', ['A', 'B']);
    await tracker.onModuleStarted('u', m1);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('adaptive.outcomes.u');
    final data = jsonDecode(raw!);
    expect((data['m1']['baselinePass'] as num).toDouble(), closeTo(0.5, 1e-6));

    await tracker.onModuleCompleted('u', m1, passRate: 0.7);
    var stats = await tracker.getTagStats('u', 'A');
    expect(stats.n, 1);
    expect(stats.meanDelta, closeTo(0.1, 1e-6));
    expect(stats.varDelta, closeTo(0.0, 1e-6));

    final m2 = _module('m2', ['A']);
    await tracker.onModuleStarted('u', m2);
    final raw2 = prefs.getString('adaptive.outcomes.u');
    final data2 = jsonDecode(raw2!);
    expect((data2['m2']['baselinePass'] as num).toDouble(), closeTo(0.7, 1e-6));

    await tracker.onModuleCompleted('u', m2, passRate: 0.6);
    stats = await tracker.getTagStats('u', 'A');
    expect(stats.n, 2);
    expect(stats.meanDelta, closeTo(0.0, 1e-6));
    expect(stats.varDelta, closeTo(0.02, 1e-6));
  });
}
