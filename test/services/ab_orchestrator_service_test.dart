import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/ab_orchestrator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'ab.enabled': true});
    ABOrchestratorService.instance.clearCache();
  });

  test('unbiased assignment under traffic<1', () async {
    final svc = ABOrchestratorService.instance;
    final file = File('assets/ab_experiments.json');
    final orig = await file.readAsString();
    await file.writeAsString(orig.replaceFirst('"traffic": 1.0', '"traffic": 0.5'));
    addTearDown(() async {
      await file.writeAsString(orig);
      svc.clearCache();
    });
    svc.clearCache();

    final counts = <String, int>{'control': 0, 'hiImpact': 0, 'none': 0};
    for (var i = 0; i < 1000; i++) {
      final uid = 'u$i';
      final arms = await svc.resolveActiveArms(uid, 'regular');
      if (arms.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final a = prefs.getString('ab.assignment.wImpactTest.$uid')!;
        counts[a] = (counts[a] ?? 0) + 1;
      } else {
        counts[arms.first.armId] = counts[arms.first.armId]! + 1;
      }
    }
    final assigned = counts['control']! + counts['hiImpact']!;
    expect(assigned, greaterThan(0));
    final ratio = counts['control']! / assigned;
    expect(ratio, closeTo(0.5, 0.1));
    expect(counts['none']! / 1000, closeTo(0.5, 0.1));
  });

  test('assignment sticks even if traffic changes', () async {
    final svc = ABOrchestratorService.instance;
    final file = File('assets/ab_experiments.json');
    final orig = await file.readAsString();
    await file.writeAsString(orig.replaceFirst('"traffic": 1.0', '"traffic": 1.0'));
    svc.clearCache();
    final user = 'sticky';
    final first = await svc.resolveActiveArms(user, 'regular');
    final armId = first.isEmpty ? 'none' : first.first.armId;
    await file.writeAsString(orig.replaceFirst('"traffic": 1.0', '"traffic": 0.0'));
    svc.clearCache();
    final second = await svc.resolveActiveArms(user, 'regular');
    final armId2 = second.isEmpty ? 'none' : second.first.armId;
    expect(armId2, armId);
    await file.writeAsString(orig);
    svc.clearCache();
  });

  test('withOverrides restores on success and throw', () async {
    final svc = ABOrchestratorService.instance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('x', 1);
    final arm = ResolvedArm(expId: 'e', armId: 'a', prefs: {'x': 2, 'y': 3});

    await svc.withOverrides(arm, () async {
      expect(prefs.getInt('x'), 2);
      expect(prefs.getInt('y'), 3);
    });
    expect(prefs.getInt('x'), 1);
    expect(prefs.getInt('y'), isNull);

    var threw = false;
    try {
      await svc.withOverrides(arm, () async {
        expect(prefs.getInt('x'), 2);
        throw Exception('boom');
      });
    } catch (_) {
      threw = true;
    }
    expect(threw, true);
    expect(prefs.getInt('x'), 1);
    expect(prefs.getInt('y'), isNull);
  });
}
