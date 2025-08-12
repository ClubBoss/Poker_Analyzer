import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/import_mistake_packs.dart <file.csv>');
    exit(1);
  }
  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('File not found: ${args.first}');
    exit(1);
  }
  final rows = const CsvToListConverter().convert(file.readAsStringSync().trim());
  if (rows.isEmpty) {
    stderr.writeln('Empty CSV');
    exit(1);
  }
  final header = [for (final h in rows.first) h.toString().trim()];
  final Map<String, int> idx = {for (var i = 0; i < header.length; i++) header[i]: i};
  final required = [
    'group',
    'title',
    'heroHand',
    'position',
    'heroBbStack',
    'playerStacksBb',
    'actionsJson'
  ];
  for (final r in required) {
    if (!idx.containsKey(r)) {
      stderr.writeln('Missing column: $r');
      exit(1);
    }
  }
  final map = <String, List<List<dynamic>>>{};
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final g = _cell(row, idx['group']);
    if (g.isEmpty) continue;
    map.putIfAbsent(g, () => []).add(row);
  }
  final outDir = Directory('./out')..createSync(recursive: true);
  var done = 0;
  final total = map.length;
  final start = DateTime.now();
  for (final entry in map.entries) {
    done++;
    final group = entry.key;
    try {
      final spots = <TrainingPackSpot>[];
      for (var i = 0; i < entry.value.length; i++) {
        final row = entry.value[i];
        final title = _cell(row, idx['title']);
        final hand = _cell(row, idx['heroHand']);
        final pos = parseHeroPosition(_cell(row, idx['position']));
        final heroStack = _int(_cell(row, idx['heroBbStack'])) ?? 0;
        final others = _list(_cell(row, idx['playerStacksBb']));
        final stacks = [heroStack, ...others];
        final acts = _actions(_cell(row, idx['actionsJson']));
        final heroEv = _double(_cell(row, idx['heroEv']));
        final heroIcm = _double(_cell(row, idx['heroIcmEv']));
        if (heroEv != null || heroIcm != null) {
          final list0 = acts[0];
          if (list0 != null) {
            for (var k = 0; k < list0.length; k++) {
              final a = list0[k];
              if (a.playerIndex == 0) {
                list0[k] = a.copyWith(
                  ev: heroEv ?? a.ev,
                  icmEv: heroIcm ?? a.icmEv,
                );
              }
            }
          }
        }
        spots.add(
          TrainingPackSpot(
            id: '${group}_${i + 1}',
            title: title,
            hand: HandData(
              heroCards: hand,
              position: pos,
              heroIndex: 0,
              playerCount: stacks.length,
              stacks: {for (var j = 0; j < stacks.length; j++) '$j': stacks[j].toDouble()},
              actions: acts,
            ),
            tags: const [],
          ),
        );
      }
      if (spots.isEmpty) continue;
      final first = entry.value.first;
      final tpl = TrainingPackTemplate(
        id: group,
        name: group,
        spots: spots,
        heroBbStack: _int(_cell(first, idx['heroBbStack'])) ?? 0,
        playerStacksBb: [
          _int(_cell(first, idx['heroBbStack'])) ?? 0,
          ..._list(_cell(first, idx['playerStacksBb']))
        ],
        heroPos: parseHeroPosition(_cell(first, idx['position'])),
      );
      final issues = validateTrainingPackTemplate(tpl);
      if (issues.isNotEmpty) throw issues.join('; ');
      final path = p.join(outDir.path, '$group.json');
      File(path).writeAsStringSync(jsonEncode(tpl.toJson()));
      stdout.writeln('[$done/$total] $group - ${spots.length} spots');
    } catch (e) {
      stderr.writeln('[$done/$total] $group - [ERROR] $e');
    }
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
}

String _cell(List row, int? i) {
  if (i == null || i >= row.length) return '';
  return row[i].toString().trim();
}

int? _int(String v) {
  final t = v.trim();
  if (t.isEmpty) return null;
  return int.tryParse(t);
}

double? _double(String v) {
  final t = v.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t.replaceAll(',', '.'));
}

List<int> _list(String v) {
  return [for (final s in v.split('/')) if (s.trim().isNotEmpty) _int(s.trim()) ?? 0];
}

Map<int, List<ActionEntry>> _actions(String v) {
  final map = <int, List<ActionEntry>>{for (var s = 0; s < 4; s++) s: []};
  if (v.trim().isEmpty) return map;
  final decoded = jsonDecode(v);
  if (decoded is Map) {
    decoded.forEach((key, value) {
      final k = int.tryParse(key.toString()) ?? 0;
      if (value is List) {
        map[k] = [
          for (final a in value)
            if (a is Map)
              ActionEntry.fromJson(Map<String, dynamic>.from(a))
        ];
      }
    });
  }
  return map;
}
