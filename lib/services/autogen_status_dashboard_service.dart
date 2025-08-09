import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/autogen_status.dart';
import '../models/autogen_session_meta.dart';
import '../models/training_run_record.dart';
import '../core/models/spot_seed/seed_issue.dart';
import 'training_run_ab_comparator.dart';
import 'autogen_pipeline_executor.dart';

class DuplicatePackInfo {
  final String candidateId;
  final String existingId;
  final double similarity;
  final String reason;

  const DuplicatePackInfo({
    required this.candidateId,
    required this.existingId,
    required this.similarity,
    required this.reason,
  });
}

class AutogenStatusDashboardService {
  AutogenStatusDashboardService._();

  static final AutogenStatusDashboardService _instance =
      AutogenStatusDashboardService._();

  factory AutogenStatusDashboardService() => _instance;
  static AutogenStatusDashboardService get instance => _instance;

  final Map<String, AutogenStatus> _statuses = {};
  final ValueNotifier<Map<String, AutogenStatus>> notifier = ValueNotifier(
    const <String, AutogenStatus>{},
  );

  final ValueNotifier<List<DuplicatePackInfo>> duplicatesNotifier =
      ValueNotifier(const <DuplicatePackInfo>[]);

  final ValueNotifier<int> boostersGeneratedNotifier = ValueNotifier(0);
  final ValueNotifier<Map<String, int>> boostersSkippedNotifier = ValueNotifier(
    const {},
  );
  final ValueNotifier<List<String>> boosterIdsNotifier = ValueNotifier(
    const <String>[],
  );

  final ValueNotifier<int> theoryClustersInjectedNotifier = ValueNotifier(0);
  final ValueNotifier<int> theoryLinksInjectedNotifier = ValueNotifier(0);

  final ValueNotifier<int> pathModulesInjectedNotifier = ValueNotifier(0);
  final ValueNotifier<int> pathModulesInProgressNotifier = ValueNotifier(0);
  final ValueNotifier<int> pathModulesCompletedNotifier = ValueNotifier(0);
  final ValueNotifier<double> avgPassRateNotifier = ValueNotifier(0.0);

  final ValueNotifier<List<ABArmResult>> abResultsNotifier = ValueNotifier(
    const <ABArmResult>[],
  );
  final TrainingRunABComparator _abComparator = TrainingRunABComparator();

  /// Issues discovered during seed validation.
  final ValueNotifier<List<SeedIssue>> seedIssuesNotifier = ValueNotifier(
    const <SeedIssue>[],
  );

  final List<AutogenSessionMeta> _sessions = [];
  final StreamController<List<AutogenSessionMeta>> _sessionController =
      StreamController.broadcast();
  static const _sessionTtl = Duration(hours: 24);

  // Real-time pipeline status.
  final ValueNotifier<AutogenStatus> pipelineStatusNotifier =
      ValueNotifier(const AutogenStatus());
  final StreamController<AutogenStatus> _statusStreamController =
      StreamController.broadcast();
  StreamSubscription<AutogenStatus>? _statusSub;
  final List<String> _recentErrors = [];
  final List<AutogenStatus> _runSummaries = [];
  static const _runSummariesKey = 'autogen.runSummaries';
  AutogenRunState _previousState = AutogenRunState.idle;
  AutogenStatus _lastStatus = const AutogenStatus();

  void update(String module, AutogenStatus status) {
    _statuses[module] = status;
    notifier.value = Map.unmodifiable(_statuses);
  }

  ValueListenable<AutogenStatus> get pipelineStatus => pipelineStatusNotifier;
  Stream<AutogenStatus> get statusStream => _statusStreamController.stream;
  List<String> get recentErrors => List.unmodifiable(_recentErrors);
  List<AutogenStatus> get runSummaries => List.unmodifiable(_runSummaries);

  Future<void> bindExecutor(AutogenPipelineExecutor executor) async {
    await bindStream(executor.status$);
  }

  Future<void> bindStream(Stream<AutogenStatus> stream) async {
    await _statusSub?.cancel();
    _statusSub = stream.listen(_handleStatus);
  }

  void _handleStatus(AutogenStatus status) {
    pipelineStatusNotifier.value = status;
    _statusStreamController.add(status);
    if (status.lastErrorMsg != null && status.lastErrorMsg!.isNotEmpty) {
      _recentErrors.add(status.lastErrorMsg!);
      if (_recentErrors.length > 20) {
        _recentErrors.removeAt(0);
      }
    }
    if (_previousState == AutogenRunState.running &&
        status.state != AutogenRunState.running) {
      _persistSummary(_lastStatus);
    }
    _previousState = status.state;
    _lastStatus = status;
  }

  Future<void> _persistSummary(AutogenStatus summary) async {
    final prefs = await SharedPreferences.getInstance();
    _runSummaries.insert(0, summary);
    if (_runSummaries.length > 10) {
      _runSummaries.removeLast();
    }
    final encoded =
        _runSummaries.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_runSummariesKey, encoded);
  }

  Future<void> loadSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_runSummariesKey) ?? [];
    _runSummaries
      ..clear()
      ..addAll(list.map((e) => AutogenStatus.fromJson(jsonDecode(e))));
  }

  void registerSession(AutogenSessionMeta meta) {
    _cleanupOldSessions();
    _sessions.removeWhere((s) => s.sessionId == meta.sessionId);
    _sessions.add(meta);
    _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _sessionController.add(List.unmodifiable(_sessions));
  }

  void updateSessionStatus(String sessionId, String status) {
    _cleanupOldSessions();
    final index = _sessions.indexWhere((s) => s.sessionId == sessionId);
    if (index != -1) {
      final s = _sessions[index];
      _sessions[index] = s.copyWith(status: status);
      _sessionController.add(List.unmodifiable(_sessions));
    }
  }

  List<AutogenSessionMeta> getRecentSessions() {
    _cleanupOldSessions();
    return List.unmodifiable(_sessions);
  }

  Stream<List<AutogenSessionMeta>> watchSessions() => _sessionController.stream;

  AutogenStatus? getStatus(String module) => _statuses[module];

  final Map<String, ValueNotifier<AutogenStatus>> _moduleNotifiers = {};

  /// Returns a [ValueListenable] that emits updates for [module].
  ValueListenable<AutogenStatus> getStatusNotifier(String module) {
    return _moduleNotifiers.putIfAbsent(module, () {
      final vn = ValueNotifier<AutogenStatus>(
        _statuses[module] ?? const AutogenStatus(),
      );
      notifier.addListener(() {
        final s = _statuses[module];
        if (s != null) vn.value = s;
      });
      return vn;
    });
  }

  Map<String, AutogenStatus> getAll() => Map.unmodifiable(_statuses);

  List<DuplicatePackInfo> get duplicates =>
      List.unmodifiable(duplicatesNotifier.value);

  void flagDuplicate(
    String candidateId,
    String existingId,
    String reason,
    double similarity,
  ) {
    final list = [...duplicatesNotifier.value];
    list.add(
      DuplicatePackInfo(
        candidateId: candidateId,
        existingId: existingId,
        similarity: similarity,
        reason: reason,
      ),
    );
    duplicatesNotifier.value = List.unmodifiable(list);
  }

  void recordBoosterGenerated(String id) {
    boostersGeneratedNotifier.value = boostersGeneratedNotifier.value + 1;
    final list = [...boosterIdsNotifier.value, id];
    boosterIdsNotifier.value = List.unmodifiable(list);
  }

  void recordBoosterSkipped(String reason) {
    final map = Map<String, int>.from(boostersSkippedNotifier.value);
    map[reason] = (map[reason] ?? 0) + 1;
    boostersSkippedNotifier.value = Map.unmodifiable(map);
  }

  void recordTheoryInjection({int clusters = 0, int links = 0}) {
    if (clusters != 0) {
      theoryClustersInjectedNotifier.value =
          theoryClustersInjectedNotifier.value + clusters;
    }
    if (links != 0) {
      theoryLinksInjectedNotifier.value =
          theoryLinksInjectedNotifier.value + links;
    }
  }

  void recordPathModuleInjected() {
    pathModulesInjectedNotifier.value = pathModulesInjectedNotifier.value + 1;
  }

  void recordPathModuleStarted() {
    pathModulesInProgressNotifier.value =
        pathModulesInProgressNotifier.value + 1;
  }

  void recordPathModuleCompleted(double passRate) {
    pathModulesCompletedNotifier.value = pathModulesCompletedNotifier.value + 1;
    final total = pathModulesCompletedNotifier.value;
    avgPassRateNotifier.value =
        ((avgPassRateNotifier.value * (total - 1)) + passRate) / total;
  }

  /// Append [issues] for [seedId] to the lint feed.
  void reportSeedIssues(String seedId, List<SeedIssue> issues) {
    if (issues.isEmpty) return;
    final list = [...seedIssuesNotifier.value];
    list.addAll(
      issues.map(
        (i) => SeedIssue(
          code: i.code,
          severity: i.severity,
          message: i.message,
          path: i.path,
          seedId: seedId,
        ),
      ),
    );
    seedIssuesNotifier.value = List.unmodifiable(list);
  }

  Future<void> refreshAbResults(
    List<TrainingRunRecord> runs, {
    String? audience,
  }) async {
    final results = await _abComparator.compare(runs, audience: audience);
    abResultsNotifier.value = List.unmodifiable(results);
  }

  void _cleanupOldSessions() {
    final cutoff = DateTime.now().subtract(_sessionTtl);
    final before = _sessions.length;
    _sessions.removeWhere((s) => s.startedAt.isBefore(cutoff));
    if (_sessions.length != before) {
      _sessionController.add(List.unmodifiable(_sessions));
    }
  }

  @visibleForTesting
  void clear() {
    _statuses.clear();
    notifier.value = const <String, AutogenStatus>{};
    _sessions.clear();
    _sessionController.add(const <AutogenSessionMeta>[]);
    duplicatesNotifier.value = const <DuplicatePackInfo>[];
    boostersGeneratedNotifier.value = 0;
    boostersSkippedNotifier.value = const {};
    boosterIdsNotifier.value = const <String>[];
    seedIssuesNotifier.value = const <SeedIssue>[];
    pathModulesInjectedNotifier.value = 0;
    pathModulesInProgressNotifier.value = 0;
    pathModulesCompletedNotifier.value = 0;
    avgPassRateNotifier.value = 0.0;
    theoryClustersInjectedNotifier.value = 0;
    theoryLinksInjectedNotifier.value = 0;
    pipelineStatusNotifier.value = const AutogenStatus();
    _recentErrors.clear();
    _runSummaries.clear();
    _statusSub?.cancel();
    _previousState = AutogenRunState.idle;
    _lastStatus = const AutogenStatus();
  }
}
