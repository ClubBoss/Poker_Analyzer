import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import 'learning_path_store.dart';
import 'mistake_telemetry_store.dart';
import 'theory_library_index.dart';
import 'theory_link_auto_injector.dart';
import 'theory_link_config_service.dart';
import 'theory_link_policy_engine.dart';
import 'theory_novelty_registry.dart';
import 'auto_run_mutex.dart';

class TheoryInjectionSchedulerService {
  TheoryInjectionSchedulerService._({
    LearningPathStore? store,
    AutogenStatusDashboardService? dashboard,
  }) : _store = store ?? const LearningPathStore(),
       _dashboard = dashboard ?? AutogenStatusDashboardService.instance;

  static final TheoryInjectionSchedulerService instance =
      TheoryInjectionSchedulerService._();

  final LearningPathStore _store;
  late final TheoryLinkAutoInjector _injector;
  final AutogenStatusDashboardService _dashboard;
  final AutoRunMutex _mutex = AutoRunMutex();
  bool _initialized = false;

  Timer? _timer;
  int _totalRuns = 0;
  int _totalSkipped = 0;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('theory.schedulerEnabled') ?? true)) return;
    if (!_initialized) {
      _injector = TheoryLinkAutoInjector(
        store: _store,
        libraryIndex: TheoryLibraryIndex(),
        telemetry: MistakeTelemetryStore(),
        noveltyRegistry: TheoryNoveltyRegistry(),
        policy: TheoryLinkPolicyEngine(prefs: prefs),
        config: TheoryLinkConfigService.instance,
      );
      _initialized = true;
    }
    final intervalHours = prefs.getInt('theory.schedulerIntervalHours') ?? 6;
    await runNow();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(hours: intervalHours), (_) => runNow());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> runNow({bool force = false}) async {
    if (_mutex.isRunning && force) {
      _dashboard.update(
        'TheoryInjectionScheduler',
        const AutogenStatus(isRunning: true, currentStage: 'queued'),
      );
    }
    await _mutex.run(() async {
      final prefs = await SharedPreferences.getInstance();
      final intervalHours = prefs.getInt('theory.schedulerIntervalHours') ?? 6;
      final interval = Duration(hours: intervalHours);
      final now = DateTime.now();
      final users = await _store.listUsers();
      var injected = 0;
      var skipped = 0;
      for (final user in users) {
        final key = 'theoryScheduler.lastRun.$user';
        final lastRaw = prefs.getString(key);
        final last = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
        if (!force && last != null && now.difference(last) < interval) {
          skipped++;
          continue;
        }
        final modules = await _store.listModules(user);
        final pending = modules.where(
          (m) => m.status == 'pending' || m.status == 'in_progress',
        );
        final injector = _injector;
        if (pending.isEmpty ||
            pending.every((m) => m.theoryIds.length >= injector.maxPerModule)) {
          skipped++;
          await prefs.setString(key, now.toIso8601String());
          continue;
        }
        await injector.injectForUser(user);
        await prefs.setString(key, now.toIso8601String());
        injected++;
      }
      _totalRuns += injected;
      _totalSkipped += skipped;
      _dashboard.update(
        'TheoryInjectionScheduler',
        AutogenStatus(
          isRunning: false,
          currentStage: jsonEncode({
            'runs': _totalRuns,
            'skipped': _totalSkipped,
          }),
        ),
      );
    }, force: force);
  }
}
