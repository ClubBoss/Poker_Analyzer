import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/services/training_pack_library_exporter.dart';

void main() {
  TrainingPackModel buildPack(String id, String title, {List<String>? tags}) {
    return TrainingPackModel(
      id: id,
      title: title,
      spots: [TrainingPackSpot(id: 's$id', hand: HandData())],
      tags: tags,
    );
  }

  test('exportToMap exports multiple packs', () {
    final exporter = TrainingPackLibraryExporter();
    final packs = [
      buildPack('p1', 'Pack 1', tags: ['a']),
      buildPack('p2', 'Pack 2'),
    ];
    final map = exporter.exportToMap(packs);
    expect(map.length, 2);
    expect(map.containsKey('p1.yaml'), true);
    expect(map.containsKey('p2.yaml'), true);
    final yaml = map['p1.yaml']!;
    expect(yaml.contains('id: p1'), true);
    expect(yaml.contains('title: Pack 1'), true);
  });

  test('exportToMap handles empty list', () {
    final exporter = TrainingPackLibraryExporter();
    final map = exporter.exportToMap([]);
    expect(map, isEmpty);
  });

  test('saveToDirectory writes correct files and content', () async {
    final exporter = TrainingPackLibraryExporter();
    final dir = await Directory.systemTemp.createTemp();
    final pack = buildPack('p1', 'Pack 1');
    final paths = await exporter.saveToDirectory([pack], dir.path);
    expect(paths.length, 1);
    final file = File('${dir.path}/p1.yaml');
    expect(await file.exists(), true);
    final content = await file.readAsString();
    expect(content.contains('id: p1'), true);
    expect(content.contains('title: Pack 1'), true);
    await dir.delete(recursive: true);
  });
}
