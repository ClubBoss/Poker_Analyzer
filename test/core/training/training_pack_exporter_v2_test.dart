import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'package:poker_analyzer/core/training/export/training_pack_exporter_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/theory_yaml_safe_writer.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final packsDir = Directory('packs');
    if (packsDir.existsSync()) packsDir.deleteSync(recursive: true);
  });

  test('exporter uses safe writer and preserves header', () async {
    final tpl = TrainingPackTemplateV2(
      id: '1',
      name: 'T',
      description: '',
      goal: '',
      trainingType: TrainingType.pushFold,
      spots: [],
      spotCount: 0,
      positions: [],
      bb: 0,
      gameType: GameType.cash,
      tags: [],
    );
    final exporter = TrainingPackExporterV2();
    final file = await exporter.exportToFile(tpl, fileName: 'test_pack');
    final first = await file.readAsString();
    final prev = TheoryYamlSafeWriter.extractHash(first);
    expect(prev, isNotNull);
    await exporter.exportToFile(tpl, fileName: 'test_pack');
    final secondLines = await file.readAsLines();
    expect(secondLines.first.contains('| x-ver: 1'), isTrue);
    final hash2 = TheoryYamlSafeWriter.extractHash(await file.readAsString());
    expect(hash2, equals(prev));
  });
}
