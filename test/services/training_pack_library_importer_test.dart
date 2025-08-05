import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_library_importer.dart';

void main() {
  const validPack1 = '''
id: p1
title: Pack 1
tags:
  - a
spots:
  - id: s1
    hand: {}
''';
  const validPack2 = '''
id: p2
title: Pack 2
spots:
  - id: s2
    hand: {}
''';

  test('importFromMap imports multiple valid packs', () {
    final importer = TrainingPackLibraryImporter();
    final packs = importer.importFromMap({
      'p1.yaml': validPack1,
      'p2.yaml': validPack2,
    });
    expect(importer.errors, isEmpty);
    expect(packs.length, 2);
    expect(packs.first.id, 'p1');
    expect(packs[1].title, 'Pack 2');
  });

  test('importFromMap handles malformed YAML', () {
    final importer = TrainingPackLibraryImporter();
    final packs = importer.importFromMap({'bad.yaml': 'id: 1\ntitle Pack'});
    expect(packs, isEmpty);
    expect(importer.errors, isNotEmpty);
  });

  test('importFromMap skips packs with missing fields', () {
    final importer = TrainingPackLibraryImporter();
    final packs = importer.importFromMap({
      'missing_title.yaml': 'id: x\nspots: []',
      'missing_spots.yaml': 'id: y\ntitle: T',
    });
    expect(packs, isEmpty);
    expect(importer.errors.length, 2);
  });

  test('loadFromDirectory reads packs from disk', () async {
    final dir = await Directory.systemTemp.createTemp();
    await File('${dir.path}/p1.yaml').writeAsString(validPack1);
    final importer = TrainingPackLibraryImporter();
    final packs = await importer.loadFromDirectory(dir.path);
    expect(importer.errors, isEmpty);
    expect(packs.length, 1);
    expect(packs.first.title, 'Pack 1');
    await dir.delete(recursive: true);
  });
}

