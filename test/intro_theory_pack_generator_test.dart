import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/services/intro_theory_pack_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackTemplateV2 _pack(
  String id,
  List<TrainingPackSpot> spots,
  List<String> tags,
) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    tags: tags,
    spots: spots,
    spotCount: spots.length,
  );
}

TrainingPackSpot _spot(String id, String tag, {String type = 'theory'}) {
  return TrainingPackSpot(id: id, type: type, tags: [tag], hand: HandData());
}

void main() {
  test('generate creates packs for tags with >=2 spots', () async {
    final dir = await Directory.systemTemp.createTemp('intro_test');
    final src = Directory(p.join(dir.path, 'src'))..createSync();
    final out = Directory(p.join(dir.path, 'out'));
    try {
      final p1 = _pack(
        'p1',
        [_spot('a', 'btnPush'), _spot('b', 'btnPush')],
        ['btnPush'],
      );
      final p2 = _pack('p2', [_spot('c', 'limped')], ['limped']);
      await File(p.join(src.path, 'p1.yaml')).writeAsString(p1.toYamlString());
      await File(p.join(src.path, 'p2.yaml')).writeAsString(p2.toYamlString());

      final gen = IntroTheoryPackGenerator();
      final count = await gen.generate(src: src.path, out: out.path);

      expect(count, 1);
      expect(File(p.join(out.path, 'btnPush_intro.yaml')).existsSync(), isTrue);
      expect(File(p.join(out.path, 'limped_intro.yaml')).existsSync(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
