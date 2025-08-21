import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_cluster_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export clusters copies packs', () async {
    final dir = Directory.systemTemp.createTempSync();
    final packsDir = Directory('${dir.path}/packs')..createSync();
    final file = File('${packsDir.path}/p1.yaml');
    await file.writeAsString('''
id: p1
name: Test Pack
trainingType: tournament
spots:
  - id: s1
    heroOptions: [open, fold]
    villainAction: none
    hand:
      position: utg
      heroIndex: 0
      playerCount: 2
      stacks:
        '0': 20
        '1': 20
spotCount: 1
meta:
  schemaVersion: 2.0.0
''');

    final exporter = BoosterPackClusterExporter();
    final count = await exporter.export(src: packsDir.path, dst: dir.path);
    expect(count, 1);
    final clusters = dir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.contains('cluster_'))
        .toList();
    expect(clusters.isNotEmpty, true);
    final copied = clusters.first.listSync().whereType<File>().any(
          (f) => f.path.endsWith('p1.yaml'),
        );
    expect(copied, true);
  });
}
