import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';
import 'learning_path_personalization_service.dart';
import 'pack_library_loader_service.dart';
import 'smart_recommender_engine.dart';
import 'training_progress_logger.dart';

import '../models/training_result.dart';

import '../models/session_log.dart';
import 'training_session_service.dart';

class StageStats {
  final int handsPlayed;
  final double accuracy;
  const StageStats({required this.handsPlayed, required this.accuracy});
}

/// Accuracy trend entry for a single session.
class StageTrendPoint {
  final DateTime date;
  final double accuracy;
  const StageTrendPoint({required this.date, required this.accuracy});
}

/// Extended stats including recent session history.
class StageStatsWithHistory extends StageStats {
  final List<StageTrendPoint> history;
  const StageStatsWithHistory({
    required int handsPlayed,
    required double accuracy,
    required this.history,
  }) : super(handsPlayed: handsPlayed, accuracy: accuracy);
}

class SessionLogService extends ChangeNotifier {
  SessionLogService({required TrainingSessionService sessions, this.cloud})
      : _sessions = sessions {
    _listener = _handle;
    _sessions.addListener(_listener!);
  }

  final TrainingSessionService _sessions;
  final CloudSyncService? cloud;
  static const _timeKey = 'session_logs_updated';
  Box<dynamic>? _box;
  VoidCallback? _listener;
  final List<SessionLog> _logs = [];
  final Set<String> _logged = {};

  List<SessionLog> get logs => List.unmodifiable(_logs);

  StageStats getStats(String templateId) {
    int hands = 0;
    int correct = 0;
    for (final log in _logs) {
      if (log.templateId == templateId) {
        hands += log.correctCount + log.mistakeCount;
        correct += log.correctCount;
      }
    }
    final acc = hands == 0 ? 0.0 : correct / hands * 100;
    return StageStats(handsPlayed: hands, accuracy: acc);
  }

  /// Returns aggregated stats along with recent session history for [templateId].
  StageStatsWithHistory getStatsWithHistory(
    String templateId, [
    int recent = 7,
  ]) {
    int hands = 0;
    int correct = 0;
    final history = <StageTrendPoint>[];
    for (final log in _logs) {
      if (log.templateId != templateId) continue;
      final total = log.correctCount + log.mistakeCount;
      hands += total;
      correct += log.correctCount;
      if (history.length < recent) {
        final acc = total == 0 ? 0.0 : log.correctCount / total * 100;
        history.add(StageTrendPoint(date: log.completedAt, accuracy: acc));
      }
    }
    history.sort((a, b) => a.date.compareTo(b.date));
    final acc = hands == 0 ? 0.0 : correct / hands * 100;
    return StageStatsWithHistory(
      handsPlayed: hands,
      accuracy: acc,
      history: history,
    );
  }

  Future<void> load() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('session_logs');
    } else {
      _box = Hive.box('session_logs');
    }
    _logs
      ..clear()
      ..addAll(
        _box!.values.whereType<Map>().map(
              (e) => SessionLog.fromJson(Map<String, dynamic>.from(e)),
            ),
      )
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _logged.addAll(_logs.map((e) => e.sessionId));
    if (cloud != null) {
      final remote = cloud!.getCached('session_logs');
      if (remote != null) {
        final prefs = await SharedPreferences.getInstance();
        final remoteAt =
            DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final localAt = DateTime.tryParse(prefs.getString(_timeKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (remoteAt.isAfter(localAt)) {
          final list = remote['logs'];
          if (list is List) {
            _logs
              ..clear()
              ..addAll(
                list.map(
                  (e) =>
                      SessionLog.fromJson(Map<String, dynamic>.from(e as Map)),
                ),
              )
              ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
            _logged
              ..clear()
              ..addAll(_logs.map((e) => e.sessionId));
            await _persist();
          }
        } else if (localAt.isAfter(remoteAt)) {
          await cloud!.uploadSessionLogs(_logs);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _save(SessionLog log) async {
    _logs.insert(0, log);
    await _box!.put(log.sessionId, log.toJson());
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, DateTime.now().toIso8601String());
    if (cloud != null) {
      await cloud!.uploadSessionLogs(_logs);
    }
    notifyListeners();
  }

  Future<void> addLog(SessionLog log) async {
    if (_box == null) await load();
    if (_logged.contains(log.sessionId)) return;
    _logged.add(log.sessionId);
    await _save(log);
  }

  void _handle() {
    final s = _sessions.session;
    if (s == null || s.completedAt == null) return;
    if (_logged.contains(s.id)) return;
    final correct = _sessions.correctCount;
    final cats = <String, int>{};
    for (final e in _sessions.getCategoryStats().entries) {
      final miss = e.value.played - e.value.correct;
      if (miss > 0) cats[e.key] = miss;
    }
    final tags = <String>{
      ...?_sessions.template?.tags,
      ..._sessions.sessionTags,
    };
    final meta = TrainingProgressLogger.consumeMeta(
      _sessions.template?.id ?? '',
    );
    final log = SessionLog(
      sessionId: s.id,
      templateId: s.templateId,
      startedAt: s.startedAt,
      completedAt: s.completedAt!,
      correctCount: correct,
      mistakeCount: s.results.length - correct,
      evPercent: meta?.evPercent,
      accuracyBefore: meta?.accuracyBefore,
      accuracyAfter: meta?.accuracyAfter,
      handsBefore: meta?.handsBefore,
      handsAfter: meta?.handsAfter,
      unlockGoalReached: meta?.unlockGoalReached,
      categories: cats,
      tags: tags.toList(),
    );
    _logged.add(s.id);
    unawaited(_save(log));
    unawaited(
      LearningPathPersonalizationService.instance.updateFromSession(log),
    );
    unawaited(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'mistakes_tpl_${log.templateId}',
        log.mistakeCount > 0,
      );
    }());
  }

  List<SessionLog> filter({DateTimeRange? range, String? templateId}) {
    return [
      for (final l in _logs)
        if ((range == null ||
                (!l.completedAt.isBefore(range.start) &&
                    !l.completedAt.isAfter(range.end))) &&
            (templateId == null || l.templateId == templateId))
          l,
    ];
  }

  Map<String, int> getRecentMistakes([int days = 7]) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final map = <String, int>{};
    for (final l in _logs) {
      if (l.completedAt.isBefore(cutoff)) break;
      for (final e in l.categories.entries) {
        map[e.key] = (map[e.key] ?? 0) + e.value;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  /// Builds [UserProgress] from stored session logs.
  Future<UserProgress> getUserProgress() async {
    await load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };
    final history = <TrainingResult>[];
    for (final log in _logs) {
      final tpl = library[log.templateId];
      final tags = tpl?.tags ?? const <String>[];
      final total = log.correctCount + log.mistakeCount;
      final acc = total > 0 ? log.correctCount / total * 100 : 0.0;
      history.add(
        TrainingResult(
          date: log.completedAt,
          total: total,
          correct: log.correctCount,
          accuracy: acc,
          tags: tags,
        ),
      );
    }
    return UserProgress(history: history);
  }

  @override
  void dispose() {
    if (_listener != null) _sessions.removeListener(_listener!);
    super.dispose();
  }
}
