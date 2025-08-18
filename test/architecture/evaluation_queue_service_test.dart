import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/evaluation_queue_service.dart';
import 'package:poker_analyzer/models/action_evaluation_request.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

ActionEvaluationRequest _req(String id, int street, int player, String action) {
  return ActionEvaluationRequest(
    id: id,
    street: street,
    playerIndex: player,
    action: action,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late EvaluationQueueService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    service = EvaluationQueueService();
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('removeDuplicateEvaluations', () async {
    await service.queueLock.synchronized(() {
      service.pending.addAll([
        _req('a', 0, 0, 'call'),
        _req('b', 1, 1, 'raise'),
        _req('a', 0, 1, 'bet'),
      ]);
      service.failed.addAll([_req('b', 2, 0, 'fold'), _req('c', 2, 0, 'call')]);
      service.completed.addAll([
        _req('c', 3, 0, 'bet'),
        _req('a', 1, 0, 'raise'),
      ]);
    });

    final removed = await service.removeDuplicateEvaluations();

    expect(removed, 4);
    expect(service.pending.map((e) => e.id).toList(), ['a', 'b']);
    expect(service.failed.map((e) => e.id).toList(), ['c']);
    expect(service.completed, isEmpty);
  });

  test('resolveQueueConflicts', () async {
    await service.queueLock.synchronized(() {
      service.pending.addAll([
        _req('x', 0, 0, 'call'),
        _req('z', 1, 0, 'bet'),
        _req('y', 2, 0, 'raise'),
      ]);
      service.failed.addAll([
        _req('x', 0, 1, 'fold'),
        _req('y', 1, 1, 'call'),
        _req('z', 2, 1, 'call'),
      ]);
      service.completed.addAll([
        _req('x', 0, 0, 'bet'),
        _req('y', 1, 0, 'bet'),
      ]);
    });

    final removed = await service.resolveQueueConflicts();

    expect(removed, 5);
    expect(service.completed.map((e) => e.id).toList(), ['x', 'y']);
    expect(service.failed.map((e) => e.id).toList(), ['z']);
    expect(service.pending, isEmpty);
  });

  test('sortQueues', () async {
    await service.queueLock.synchronized(() {
      service.pending.addAll([
        _req('a', 1, 1, 'raise'),
        _req('b', 0, 1, 'check'),
        _req('c', 0, 0, 'call'),
        _req('d', 0, 0, 'bet'),
      ]);
      service.failed.addAll([
        _req('e', 2, 1, 'fold'),
        _req('f', 0, 0, 'raise'),
      ]);
      service.completed.addAll([
        _req('g', 0, 2, 'call'),
        _req('h', 0, 2, 'bet'),
      ]);
    });

    await service.sortQueues();

    expect(service.pending.map((e) => e.id).toList(), ['d', 'c', 'b', 'a']);
    expect(service.failed.map((e) => e.id).toList(), ['f', 'e']);
    expect(service.completed.map((e) => e.id).toList(), ['h', 'g']);
  });
}
