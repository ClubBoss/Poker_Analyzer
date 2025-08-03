import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_log.dart';
import 'session_log_service.dart';

import '../models/result_entry.dart';
import '../models/cloud_training_session.dart';

class CloudTrainingHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  Future<void> init() async {
    final prefs = await PreferencesService.getInstance();
    final ts = prefs.getString('history_sync_ts');
    if (ts != null) lastSync.value = DateTime.tryParse(ts);
  }

  Future<void> saveSession(List<ResultEntry> results) async {
    if (_uid == null) return;
    final data = CloudTrainingSession(path: '', date: DateTime.now(), results: results).toJson();
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .add(data);
  }

  Future<List<CloudTrainingSession>> loadSessions() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .orderBy('date', descending: true)
        .get();
    return [
      for (final d in snap.docs)
        CloudTrainingSession.fromJson(d.data(), path: d.id)
    ];
  }

  Future<void> deleteSession(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .doc(id)
        .delete();
  }

  Future<void> download(SessionLogService logs) async {
    final sessions = await loadSessions();
    for (final s in sessions) {
      final log = SessionLog(
        sessionId: s.path,
        templateId: '-',
        startedAt: s.date,
        completedAt: s.date,
        correctCount: s.correct,
        mistakeCount: s.mistakes,
        tags: const [],
      );
      await logs.addLog(log);
    }
    lastSync.value = DateTime.now();
    final prefs = await PreferencesService.getInstance();
    await prefs.setString('history_sync_ts', lastSync.value!.toIso8601String());
  }

  Future<void> updateSession(
    String id, {
    Map<String, dynamic>? data,
    Map<String, String>? handNotes,
    Map<String, List<String>>? handTags,
  }) async {
    if (_uid == null) return;
    final payload = <String, dynamic>{...?data};
    if (handNotes != null) payload['handNotes'] = handNotes;
    if (handTags != null) payload['handTags'] = handTags;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('training_sessions')
        .doc(id)
        .set(payload, SetOptions(merge: true));
  }
}
