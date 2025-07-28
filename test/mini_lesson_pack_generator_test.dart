import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mini_lesson_pack_generator.dart';
import 'package:poker_analyzer/services/mini_lesson_library_builder.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate groups lessons by prefix into packs', () async {
    final entries = [
      const MiniLessonEntry(tag: 'pos_btn', title: 'BTN Play', content: 'c1'),
      const MiniLessonEntry(tag: 'pos_bb', title: 'BB Play', content: 'c2'),
      const MiniLessonEntry(tag: 'icm_bubble', title: 'Bubble', content: 'c3'),
    ];
    final dir = Directory.systemTemp.createTempSync();
    final generator = MiniLessonPackGenerator();
    final files = await generator.generate(entries, dir: dir.path);
    expect(files.length, 2);

    final first = loadYaml(await files.first.readAsString()) as YamlMap;
    expect(first['pack_id'], isNotEmpty);
    expect(first['lessons'], isA<YamlList>());

    dir.deleteSync(recursive: true);
  });
}
