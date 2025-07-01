import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/v2/training_pack_template.dart';

class PackExportService {
  static Future<File> exportToCsv(TrainingPackTemplate tpl) async {
    final rows = <List<dynamic>>[
      [
        'Title',
        'HeroPosition',
        'HeroHand',
        'StackBB',
        'StacksBB',
        'HeroIndex',
        'CallsMask',
        'EV_BB',
        'ICM_EV',
        'Tags'
      ],
    ];
    for (final spot in tpl.spots) {
      final hand = spot.hand;
      final stacks = [
        for (var i = 0; i < hand.playerCount; i++)
          hand.stacks['$i']?.toString() ?? ''
      ].join('/');
      final pre = hand.actions[0] ?? [];
      final callsMask = hand.playerCount == 2
          ? ''
          : [
              for (var i = 0; i < hand.playerCount; i++)
                pre.any((a) => a.playerIndex == i && a.action == 'call')
                    ? '1'
                    : '0'
            ].join();
      rows.add([
        spot.title,
        hand.position.label,
        hand.heroCards,
        hand.stacks['${hand.heroIndex}']?.toString() ?? '',
        stacks,
        hand.heroIndex,
        callsMask,
        spot.heroEv?.toStringAsFixed(1) ?? '',
        spot.heroIcmEv?.toStringAsFixed(3) ?? '',
        spot.tags.join('|'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final base = _toSnakeCase(tpl.name);
    var path = '${dir.path}/$base.csv';
    if (await File(path).exists()) {
      path = '${dir.path}/$base_${DateTime.now().millisecondsSinceEpoch}.csv';
    }
    final file = File(path);
    await file.writeAsString(csvStr);
    return file;
  }

  static String _toSnakeCase(String input) {
    final snake = input
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .toLowerCase();
    return snake.startsWith('_') ? snake.substring(1) : snake;
  }
}
