import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/autogen_status.dart';
import '../models/autogen_session_meta.dart';

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

  final List<AutogenSessionMeta> _sessions = [];
  final StreamController<List<AutogenSessionMeta>> _sessionController =
      StreamController.broadcast();
  static const _sessionTtl = Duration(hours: 24);

  void update(String module, AutogenStatus status) {
    _statuses[module] = status;
    notifier.value = Map.unmodifiable(_statuses);
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

  Map<String, AutogenStatus> getAll() => Map.unmodifiable(_statuses);

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
  }
}
