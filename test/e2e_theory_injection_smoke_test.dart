import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/app_init_service.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';
import 'package:poker_analyzer/services/theory_injection_scheduler_service.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('scheduler -> injector -> dashboard', () async {
    final dashboard = AutogenStatusDashboardService.instance;
    dashboard.clear();
    await AppInitService.instance.init();
    const store = LearningPathStore();
    final module = InjectedPathModule(
      moduleId: 'm1',
      clusterId: 'c1',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const [],
      assessmentPackId: 'a1',
      createdAt: DateTime.now(),
      triggerReason: 'test',
      metrics: const {'clusterTags': ['math']},
    );
    await store.upsertModule('u1', module);

    await TheoryInjectionSchedulerService.instance.runNow(force: true);
    final modules = await store.listModules('u1');
    expect(modules.first.theoryIds.isNotEmpty, true);
    expect(dashboard.theoryLinksInjectedNotifier.value > 0, true);

    await TheoryInjectionSchedulerService.instance.runNow();
    final modules2 = await store.listModules('u1');
    expect(modules2.first.theoryIds.length, modules.first.theoryIds.length);
  });
}
