import 'dart:async';

import 'package:flutter/foundation.dart';

import 'autogen_run_history_logger_service.dart';
import 'autogen_status_dashboard_service.dart';

/// Periodically refreshes autogen run history while the pipeline is running.
class AutogenRealTimeStatsRefresherService {
  final AutogenRunHistoryLoggerService _historyService;
  final AutogenStatusDashboardService _statusService;
  final Duration interval;

  Timer? _timer;
  final ValueNotifier<DateTime> notifier = ValueNotifier(DateTime.now());
  List<RunMetricsEntry> _history = const [];

  /// Creates a refresher that polls [AutogenRunHistoryLoggerService] every
  /// [interval] while the autogen pipeline is running.
  AutogenRealTimeStatsRefresherService({
    AutogenRunHistoryLoggerService? historyService,
    AutogenStatusDashboardService? statusService,
    this.interval = const Duration(seconds: 10),
  }) : _historyService =
           historyService ?? const AutogenRunHistoryLoggerService(),
       _statusService =
           statusService ?? AutogenStatusDashboardService.instance {
    _statusService.notifier.addListener(_statusListener);
    _statusListener();
    // Load initial history asynchronously.
    _refresh();
  }

  /// Latest cached history entries.
  List<RunMetricsEntry> get history => _history;

  void _statusListener() {
    final running = _statusService.getStatus('pipeline')?.isRunning ?? false;
    if (running) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => _refresh());
    _refresh();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    _history = await _historyService.getHistory();
    notifier.value = DateTime.now();
  }

  /// Disposes internal resources.
  void dispose() {
    _stopTimer();
    _statusService.notifier.removeListener(_statusListener);
    notifier.dispose();
  }
}
