import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';

class PackImportService {
  static TrainingPackTemplate importFromCsv({
    required String csv,
    required String templateId,
    required String templateName,
  }) {
    final rows = const CsvToListConverter().convert(csv.trim());
    if (rows.isEmpty) throw const FormatException();
    final header = [for (final h in rows.first) h.toString().trim()];
    final Map<String, int> idx = {};
    for (var i = 0; i < header.length; i++) {
      idx[header[i]] = i;
    }
    if (!idx.containsKey('Title') || !idx.containsKey('HeroHand')) {
      throw const FormatException();
    }
    final spots = <TrainingPackSpot>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final title = _cell(row, idx['Title']!);
      final hand = _cell(row, idx['HeroHand']!);
      if (title.isEmpty || hand.isEmpty) continue;
      final pos = _parsePos(_cell(row, idx['HeroPosition']));
      final stacksStr = _cell(row, idx['StacksBB']);
      List<double> stackList;
      if (stacksStr.isEmpty) {
        final v = _parseDouble(_cell(row, idx['StackBB'])) ?? 0;
        stackList = [v, v];
      } else {
        stackList = [
          for (final s in stacksStr.split('/')) _parseDouble(s) ?? 0,
        ];
      }
      final heroIndex = int.tryParse(_cell(row, idx['HeroIndex'])) ?? 0;
      final ev = _parseDouble(_cell(row, idx['EV_BB']));
      final icmEv = _parseDouble(_cell(row, idx['ICM_EV']));
      final tags = _parseTags(_cell(row, idx['Tags']));
      final actions = {
        0: [
          for (var i = 0; i < stackList.length; i++)
            ActionEntry(
              0,
              i,
              i == heroIndex ? 'push' : 'fold',
              amount: stackList[heroIndex].toDouble(),
              ev: i == heroIndex ? ev : null,
              icmEv: i == heroIndex ? icmEv : null,
            ),
        ],
      };
      final callsMask = _cell(row, idx['CallsMask']);
      if (callsMask.isNotEmpty) {
        final mask = callsMask.padRight(stackList.length, '0');
        for (var i = 0; i < stackList.length && i < mask.length; i++) {
          if (mask[i] == '1') {
            final act = actions[0]!.firstWhere((a) => a.playerIndex == i);
            if (act.action == 'fold') {
              actions[0]![actions[0]!.indexOf(act)] = ActionEntry(
                0,
                i,
                'call',
                amount: stackList[heroIndex].toDouble(),
              );
            }
          }
        }
      }
      final stacks = {
        for (var i = 0; i < stackList.length; i++) '$i': stackList[i],
      };
      spots.add(
        TrainingPackSpot(
          id: '${templateId}_${spots.length + 1}',
          title: title,
          hand: HandData(
            heroCards: hand,
            position: pos,
            heroIndex: heroIndex,
            playerCount: stackList.length,
            stacks: stacks,
            actions: actions,
          ),
          tags: tags,
        ),
      );
    }
    return TrainingPackTemplate(
      id: templateId,
      name: templateName,
      spots: spots,
      createdAt: DateTime.now(),
    );
  }

  static TrainingPackTemplate importFromShareLink(String data) {
    final jsonStr = utf8.decode(base64Url.decode(data.trim()));
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return TrainingPackTemplate.fromJson(map);
  }

  static String _cell(List row, int? i) {
    if (i == null || i >= row.length) return '';
    return row[i].toString().trim();
  }

  static HeroPosition _parsePos(String v) {
    for (final p in HeroPosition.values) {
      if (v.toLowerCase() == p.name ||
          v.toUpperCase() == p.label.toUpperCase()) {
        return p;
      }
    }
    return HeroPosition.unknown;
  }

  static double? _parseDouble(String v) {
    if (v.isEmpty) return null;
    return double.tryParse(v.replaceAll(',', '.'));
  }

  static List<String> _parseTags(String v) {
    final list = v.split(RegExp(r'[|;]'));
    return [
      for (final t in list)
        if (t.trim().isNotEmpty) t.trim(),
      'imported',
    ];
  }
}
