import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_pack_exporter_service.dart';
import 'package:poker_analyzer/services/theory_pack_importer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TheoryPackImporterService', () {
    test('imports lessons from stage files', () async {
      final lessons = [
        TheoryMiniLessonNode(
          id: 'a',
          title: 'A',
          content: 'ca',
          stage: 'level1',
          tags: const ['x'],
          linkedPackIds: const ['p1'],
        ),
        TheoryMiniLessonNode(
          id: 'b',
          title: 'B',
          content: 'cb',
          stage: 'level2',
          tags: const ['y'],
        ),
      ];

      final dir = await Directory.systemTemp.createTemp('import_stage');
      await TheoryPackExporterService().export(lessons, dir.path);

      final imported =
          await TheoryPackImporterService().importLessons(dir.path);
      expect(imported.length, 2);
      final map = {for (final l in imported) l.id: l};
      expect(map['a']!.stage, 'level1');
      expect(map['a']!.linkedPackIds, ['p1']);
      expect(map['b']!.stage, 'level2');
    });

    test('imports lessons from cluster files', () async {
      final l1 = TheoryMiniLessonNode(
        id: 'a',
        title: 'A',
        content: '',
        tags: const ['t1'],
        nextIds: const ['b'],
      );
      final l2 = TheoryMiniLessonNode(
        id: 'b',
        title: 'B',
        content: '',
        tags: const ['t1'],
      );
      final l3 = TheoryMiniLessonNode(
        id: 'c',
        title: 'C',
        content: '',
        tags: const ['t2'],
      );

      final dir = await Directory.systemTemp.createTemp('import_cluster');
      await TheoryPackExporterService()
          .export([l1, l2, l3], dir.path, groupBy: 'cluster');

      final imported =
          await TheoryPackImporterService().importLessons(dir.path);
      expect(imported.length, 3);
      final map = {for (final l in imported) l.id: l};
      expect(map['a']!.nextIds, ['b']);
      expect(map['c']!.tags, ['t2']);
    });
  });
}
