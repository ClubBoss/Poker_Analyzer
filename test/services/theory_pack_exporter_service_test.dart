import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_pack_exporter_service.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TheoryPackExporterService', () {
    test('exports lessons grouped by stage', () async {
      final lessons = [
        TheoryMiniLessonNode(
          id: 'a',
          title: 'A',
          content: 'ca',
          stage: 'level1',
          tags: const ['x'],
        ),
        TheoryMiniLessonNode(
          id: 'b',
          title: 'B',
          content: 'cb',
          stage: 'level2',
          tags: const ['y'],
        ),
      ];
      final dir = await Directory.systemTemp.createTemp('theory_stage');
      final exporter = TheoryPackExporterService();
      final paths = await exporter.export(lessons, dir.path, groupBy: 'stage');

      expect(paths.length, 2);
      expect(File('${dir.path}/stage_level1.yaml').existsSync(), isTrue);
      final content = await File(
        '${dir.path}/stage_level1.yaml',
      ).readAsString();
      final yaml = loadYaml(content) as YamlMap;
      final items = yaml['lessons'] as YamlList;
      expect(items.length, 1);
      expect(items.first['id'], 'a');
      expect(items.first['stage'], 'level1');
    });

    test('exports lessons grouped by cluster', () async {
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

      final dir = await Directory.systemTemp.createTemp('theory_cluster');
      final exporter = TheoryPackExporterService();
      final paths = await exporter.export(
        [l1, l2, l3],
        dir.path,
        groupBy: 'cluster',
      );

      expect(paths.length, 2);
      expect(File('${dir.path}/cluster_1.yaml').existsSync(), isTrue);
      expect(File('${dir.path}/cluster_2.yaml').existsSync(), isTrue);
      final content = await File('${dir.path}/cluster_1.yaml').readAsString();
      final yaml = loadYaml(content) as YamlMap;
      final items = yaml['lessons'] as YamlList;
      expect(items.length, 2);
    });
  });
}
