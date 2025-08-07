import 'package:flutter/foundation.dart';

import '../models/autogen_status.dart';
import '../models/autogen_pipeline_stats.dart';

class AutogenStatusDashboardService {
  AutogenStatusDashboardService._();

  static final AutogenStatusDashboardService _instance =
      AutogenStatusDashboardService._();

  factory AutogenStatusDashboardService() => _instance;
  static AutogenStatusDashboardService get instance => _instance;

  final Map<String, AutogenStatus> _statuses = {};
  final ValueNotifier<Map<String, AutogenStatus>> notifier =
      ValueNotifier(const <String, AutogenStatus>{});

  AutogenPipelineStats _stats = const AutogenPipelineStats();
  final ValueNotifier<AutogenPipelineStats> statsNotifier =
      ValueNotifier(const AutogenPipelineStats());
  DateTime? _lastUpdated;

  void update(String module, AutogenStatus status) {
    _statuses[module] = status;
    notifier.value = Map.unmodifiable(_statuses);
  }

  AutogenStatus? getStatus(String module) => _statuses[module];

  Map<String, AutogenStatus> getAll() => Map.unmodifiable(_statuses);

  void updateGenerationStats({required int generated}) {
    _stats =
        _stats.copyWith(generated: _stats.generated + generated);
    _lastUpdated = DateTime.now();
    statsNotifier.value = _stats;
  }

  void updateDeduplicationStats({required int deduplicated}) {
    _stats =
        _stats.copyWith(deduplicated: _stats.deduplicated + deduplicated);
    _lastUpdated = DateTime.now();
    statsNotifier.value = _stats;
  }

  void updateCuratedStats({required int curated}) {
    _stats = _stats.copyWith(curated: _stats.curated + curated);
    _lastUpdated = DateTime.now();
    statsNotifier.value = _stats;
  }

  void updatePublishedStats({required int published}) {
    _stats =
        _stats.copyWith(published: _stats.published + published);
    _lastUpdated = DateTime.now();
    statsNotifier.value = _stats;
  }

  AutogenPipelineStats getCurrentStats() => _stats;

  DateTime? get lastUpdated => _lastUpdated;

  void reset() {
    _stats = const AutogenPipelineStats();
    _lastUpdated = null;
    statsNotifier.value = _stats;
  }
}
