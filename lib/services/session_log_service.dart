import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/session_log.dart';
import 'training_session_service.dart';

class SessionLogService extends ChangeNotifier {
  SessionLogService({required TrainingSessionService sessions})
      : _sessions = sessions {
    _listener = _handle;
    _sessions.addListener(_listener!);
  }

  final TrainingSessionService _sessions;
  Box<dynamic>? _box;
  VoidCallback? _listener;
  final List<SessionLog> _logs = [];
  final Set<String> _logged = {};

  List<SessionLog> get logs => List.unmodifiable(_logs);

  Future<void> load() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('session_logs');
    } else {
      _box = Hive.box('session_logs');
    }
    _logs
      ..clear()
      ..addAll(_box!.values.whereType<Map>().map(
          (e) => SessionLog.fromJson(Map<String, dynamic>.from(e))))
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _logged.addAll(_logs.map((e) => e.sessionId));
    notifyListeners();
  }

  Future<void> _save(SessionLog log) async {
    _logs.insert(0, log);
    await _box!.put(log.sessionId, log.toJson());
    notifyListeners();
  }

  void _handle() {
    final s = _sessions.session;
    if (s == null || s.completedAt == null) return;
    if (_logged.contains(s.id)) return;
    final correct = _sessions.correctCount;
    final log = SessionLog(
      sessionId: s.id,
      templateId: s.templateId,
      startedAt: s.startedAt,
      completedAt: s.completedAt!,
      correctCount: correct,
      mistakeCount: s.results.length - correct,
    );
    _logged.add(s.id);
    unawaited(_save(log));
  }

  List<SessionLog> filter({DateTimeRange? range, String? templateId}) {
    return [
      for (final l in _logs)
        if ((range == null ||
                (!l.completedAt.isBefore(range.start) &&
                    !l.completedAt.isAfter(range.end))) &&
            (templateId == null || l.templateId == templateId))
          l
    ];
  }

  @override
  void dispose() {
    if (_listener != null) _sessions.removeListener(_listener!);
    super.dispose();
  }
}
