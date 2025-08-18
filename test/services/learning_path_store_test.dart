import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearningPathStore', () {
    late Directory tempDir;
    late LearningPathStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lps');
      store = LearningPathStore(rootDir: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    InjectedPathModule buildModule(String id) => InjectedPathModule(
      moduleId: id,
      clusterId: 'c',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const [],
      assessmentPackId: 'a',
      createdAt: DateTime.now(),
      triggerReason: 'test',
    );

    test('persist and load', () async {
      final m = buildModule('m1');
      await store.upsertModule('u1', m);
      final list = await store.listModules('u1');
      expect(list, hasLength(1));
      expect(list.first.moduleId, 'm1');
    });

    test('update and remove', () async {
      final m = buildModule('m1');
      await store.upsertModule('u1', m);
      await store.updateModuleStatus('u1', 'm1', 'in_progress');
      var list = await store.listModules('u1');
      expect(list.first.status, 'in_progress');
      await store.removeModule('u1', 'm1');
      list = await store.listModules('u1');
      expect(list, isEmpty);
    });
  });
}
