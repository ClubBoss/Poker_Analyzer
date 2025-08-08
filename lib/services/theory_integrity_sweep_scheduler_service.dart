import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'theory_integrity_sweeper.dart';

class TheoryIntegritySweepSchedulerService {
  TheoryIntegritySweepSchedulerService._({TheoryIntegritySweeper? sweeper})
    : _sweeper = sweeper ?? TheoryIntegritySweeper();

  static final TheoryIntegritySweepSchedulerService instance =
      TheoryIntegritySweepSchedulerService._();

  final TheoryIntegritySweeper _sweeper;
  Timer? _timer;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('theory.sweep.enabled') ?? true)) return;
    final dirs = prefs.getStringList('theory.sweep.dirs') ?? const [];
    if (dirs.isEmpty) return;
    final intervalHours = prefs.getInt('theory.sweep.intervalHours') ?? 24;
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
