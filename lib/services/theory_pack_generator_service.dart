import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/game_type.dart';
import '../core/training/engine/training_type_engine.dart';

class TheoryPackGeneratorService {
  TheoryPackGeneratorService();

  static const Map<String, Map<String, String>> _titles = {
    'pushFold': {'en': 'Push/Fold Basics', 'ru': 'Основы пуш/фолда'},
    'icm': {'en': 'ICM Pressure', 'ru': 'ICM давление'},
  };

  static const Map<String, Map<String, String>> _explanations = {
    'pushFold': {
      'en':
          'When stacks drop below ~10bb, decisions simplify to **push** or **fold**.\n- Shove with profitable hands.\n- Fold the rest.',
      'ru':
          'При стеках меньше ~10бб решения сводятся к **пушу** или **фолду**.\n- Пушим с плюсовыми руками.\n- Остальное фолдим.',
    },
    'icm': {
      'en':
          'ICM focuses on chip value near payouts. Avoid marginal gambles when shorter stacks remain.',
      'ru':
          'ICM оценивает стоимость фишек перед выплатами. Избегайте маргинальных олынов, пока в игре есть короткие стеки.',
    },
  };

  /// List of all supported theory tags.
  static List<String> get tags =>
      {..._titles.keys, ..._explanations.keys}.toSet().toList();

  TrainingPackTemplateV2 generateForTag(String tag, {String lang = 'en'}) {
    final titleMap = _titles[tag];
    final expMap = _explanations[tag];
    final title = titleMap?[lang] ?? titleMap?["en"] ?? tag;
    final explanation = expMap?[lang] ?? expMap?["en"] ?? '';
    final spot = TrainingPackSpot(
      id: '${tag}_theory_1',
      type: 'theory',
      title: title,
      explanation: explanation,
      tags: [tag],
      hand: HandData(),
    );
    final tpl = TrainingPackTemplateV2(
      id: '${tag}_theory',
      name: '📘 $title',
      trainingType: TrainingType.pushFold,
      tags: [tag],
      spots: [spot],
      spotCount: 1,
      created: DateTime.now(),
      gameType: GameType.tournament,
      meta: {'schemaVersion': '2.0.0'},
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }

  /// Generates a theory pack for [tag] and writes it to `yaml_out/{tag}_theory.yaml`.
  Future<File> exportYamlForTag(String tag) async {
    final tpl = generateForTag(tag);
    final dir = Directory('yaml_out');
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${tag}_theory.yaml'));
    await file.writeAsString(tpl.toYamlString());
    return file;
  }
}
