import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/autogen_library_publisher_service.dart';

void main() {
  test('publish writes packs and logs duplicates', () async {
    final tmp = await Directory.systemTemp.createTemp('autogen_pub_test');
    final service = AutogenLibraryPublisherService(baseDir: tmp.path);

    TrainingPackModel pack(String id, List<String> tags) {
      return TrainingPackModel(
        id: id,
        title: 'Pack$id',
        spots: [TrainingPackSpot(id: 's$id')],
        tags: tags,
      );
    }

    final p1 = pack('1', ['a']);
    final p2 = pack('2', ['b']);

    await service.publish([p1, p2]);

    expect(File(p.join(tmp.path, 'pack_1.yaml')).existsSync(), isTrue);
    expect(File(p.join(tmp.path, 'pack_2.yaml')).existsSync(), isTrue);

    final indexFile = File(p.join(tmp.path, 'library_autogen_index.yaml'));
    final indexYaml = loadYaml(await indexFile.readAsString()) as YamlList;
    expect(indexYaml.length, 2);

    await service.publish([p1]);

    final logsFile = File(p.join(tmp.path, 'autogen_publish_log.json'));
    final logs = jsonDecode(await logsFile.readAsString()) as List;
    expect(logs.last['skippedDuplicates'], 1);
  });
}
