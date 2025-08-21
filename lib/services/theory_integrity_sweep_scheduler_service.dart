import 'dart:async';

import 'config_source.dart';
import 'theory_integrity_sweeper.dart';

class TheoryIntegritySweepSchedulerService {
  TheoryIntegritySweepSchedulerService._({
    TheoryIntegritySweeper? sweeper,
    ConfigSource? config,
  })  : _sweeper = sweeper ?? TheoryIntegritySweeper(config: config),
        _config = config ?? ConfigSource.empty();

  static final TheoryIntegritySweepSchedulerService instance =
      TheoryIntegritySweepSchedulerService._();

  final TheoryIntegritySweeper _sweeper;
  final ConfigSource _config;
  Timer? _timer;

  Future<void> start({ConfigSource? config}) async {
    final cfg = config ?? _config;
    if (!(cfg.getBool('theory.sweep.enabled') ?? true)) return;
    final dirs = cfg.getStringList('theory.sweep.dirs') ?? const [];
    if (dirs.isEmpty) return;
    final intervalHours = cfg.getInt('theory.sweep.intervalHours') ?? 24;
    await _sweeper.run(dirs: dirs, dryRun: true);
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(hours: intervalHours),
      (_) => _sweeper.run(dirs: dirs, dryRun: true),
    );
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
