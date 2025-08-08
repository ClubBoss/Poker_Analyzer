import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/ab_orchestrator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'ab.enabled': true});
  });

  test('deterministic assignment and overrides applied', () async {
    final svc = ABOrchestratorService.instance;
    ResolvedArm? target;
    String? user;
    for (var i = 0; i < 50; i++) {
      final u = 'user$i';
      final arms = await svc.resolveActiveArms(u, 'regular');
      if (arms.isNotEmpty) {
        target = arms.first;
        user = u;
        if (target!.prefs.isNotEmpty) break;
      }
    }
    expect(target, isNotNull);
    final arms2 = await svc.resolveActiveArms(user!, 'regular');
    expect(arms2.single.armId, target!.armId);
    await svc.applyOverrides(target!);
    final prefs = await SharedPreferences.getInstance();
    for (final e in target!.prefs.entries) {
      if (e.value is double) {
        expect(prefs.getDouble(e.key), e.value);
      }
      if (e.value is int) {
        expect(prefs.getInt(e.key), e.value);
      }
    }
  });
}
