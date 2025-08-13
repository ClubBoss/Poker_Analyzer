import 'dart:io';
import 'dart:math';

import '../core/training/generation/yaml_reader.dart';
import '../models/booster_anomaly_report.dart';
import '../models/v2/training_pack_template_v2.dart';

class BoosterAnomalyDetector {
  const BoosterAnomalyDetector();

  Future<BoosterAnomalyReport> analyzeYamlDir(String dir) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return const BoosterAnomalyReport();
    final reader = const YamlReader();
    final packs = <TrainingPackTemplateV2>[];
    for (final f in directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        packs.add(tpl);
      } catch (_) {}
    }
    return analyze(packs);
  }

  BoosterAnomalyReport analyze(List<TrainingPackTemplateV2> packs) {
    final dupHands = <String>[];
    final boards = <String, String>{};
    final repeatedBoards = <String>[];
    final evGroups = <String, List<double>>{};
    final weakExp = <String>[];
    final handMap = <String, String>{};

    for (final p in packs) {
      for (final s in p.spots) {
        final pos = s.hand.position.name;
        final cards = _normCards(s.hand.heroCards);
        if (cards.isNotEmpty) {
          final key = '$pos|$cards';
          final prev = handMap[key];
          final id = '${p.id}:${s.id}';
          if (prev != null) {
            dupHands.add('$key:$id');
          } else {
            handMap[key] = id;
          }
        }
        final board = s.board.isNotEmpty ? s.board : s.hand.board;
        final boardNorm = _normBoard(board);
        if (boardNorm.isNotEmpty) {
          final prev = boards[boardNorm];
          final id = '${p.id}:${s.id}';
          if (prev != null) {
            repeatedBoards.add('$boardNorm:$id');
          } else {
            boards[boardNorm] = id;
          }
        }
        final ev = s.heroEv ?? s.heroIcmEv;
        if (ev != null) {
          evGroups.putIfAbsent(pos, () => []).add(ev);
        }
        final exp = (s.explanation ?? '').trim().toLowerCase();
        if (exp.isEmpty ||
            exp == 'play standard' ||
            exp == 'standard' ||
            exp == 'n/a') {
          weakExp.add('${p.id}:${s.id}');
        }
      }
    }

    final outliers = <String>[];
    for (final e in evGroups.entries) {
      final values = e.value;
      if (values.length < 2) continue;
      var minVal = values.first;
      var maxVal = values.first;
      for (final v in values.skip(1)) {
        minVal = min(minVal, v);
        maxVal = max(maxVal, v);
      }
      if ((maxVal - minVal).abs() > 0.6) {
        outliers.add(
            '${e.key}:${minVal.toStringAsFixed(2)}-${maxVal.toStringAsFixed(2)}');
      }
    }

    return BoosterAnomalyReport(
      duplicatedHands: dupHands,
      repeatedBoards: repeatedBoards,
      evOutliers: outliers,
      weakExplanations: weakExp,
    );
  }

  String _normCards(String cards) {
    final parts = cards
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    parts.sort();
    return parts.join(' ');
  }

  String _normBoard(List<String> board) =>
      board.map((c) => c.toUpperCase()).join(' ');
}
