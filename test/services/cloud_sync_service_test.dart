import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/cloud_sync_service.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/models/action_evaluation_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late CloudSyncService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u'));
    SharedPreferences.setMockInitialValues({});
    service = CloudSyncService(firestore: firestore, auth: auth);
    await service.init();
  });

  test('upload and download session logs', () async {
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: 's',
        templateId: 't',
        startedAt: DateTime.utc(2024),
        completedAt: DateTime.utc(2024, 1, 1),
        correctCount: 1,
        mistakeCount: 0,
      )
    ];
    await service.uploadSessionLogs(logs);
    final snap = await firestore
        .collection('users')
        .doc('u')
        .collection('session_logs')
        .doc('main')
        .get();
    expect(snap.exists, true);
    expect((snap.data()?['logs'] as List).length, 1);
    final loaded = await service.downloadSessionLogs();
    expect(loaded.length, 1);
    expect(loaded.first.sessionId, 's');
  });

  test('upload and download session notes', () async {
    final notes = {1: 'n'};
    await service.uploadSessionNotes(notes);
    final snap = await firestore
        .collection('users')
        .doc('u')
        .collection('session_notes')
        .doc('main')
        .get();
    expect(snap.exists, true);
    expect((snap.data()?['notes'] as Map).length, 1);
    final loaded = await service.downloadSessionNotes();
    expect(loaded[1], 'n');
  });

  test('upload and download evaluation queue', () async {
    final request = ActionEvaluationRequest(
      street: 0,
      playerIndex: 0,
      action: 'fold',
    );
    final queue = {
      'pending': [request.toJson()],
      'failed': <dynamic>[],
      'completed': <dynamic>[]
    };
    await service.uploadQueue(queue);
    final snap = await firestore
        .collection('users')
        .doc('u')
        .collection('evaluation_queue')
        .doc('main')
        .get();
    expect(snap.exists, true);
    expect((snap.data()?['pending'] as List).length, 1);
    final loaded = await service.downloadQueue();
    expect((loaded?['pending'] as List).length, 1);
  });
}
