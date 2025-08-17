import 'dart:convert';
import 'dart:io';

import 'models.dart';

Future<List<UiSpot>> loadMistakeSpotsFromLogs(
    {String dir = 'out/session_logs'}) async {
  final directory = Directory(dir);
  if (!await directory.exists()) return [];
  final files = await directory
      .list()
      .where((e) => e is File && e.path.endsWith('.json'))
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  final spots = <UiSpot>[];
  for (final file in files) {
    try {
      final content = await file.readAsString();
      final root = jsonDecode(content);
      if (root is! Map) continue;
      final items = root['items'];
      if (items is! List) continue;
      for (final raw in items) {
        try {
          if (raw is! Map) continue;
          if (raw['correct'] == true) continue;
          final kind = _spotKindFromString(raw['kind'] as String?);
          if (kind == null) continue;
          spots.add(UiSpot(
            kind: kind,
            hand: raw['hand'] as String? ?? '',
            pos: raw['pos'] as String? ?? '',
            stack: raw['stack'] as String? ?? '',
            action: raw['expected'] as String? ?? '',
            vsPos: raw['vsPos']?.toString(),
            limpers: raw['limpers']?.toString(),
            explain: null,
          ));
        } catch (_) {
          // skip malformed item
        }
      }
    } catch (_) {
      // skip malformed file
    }
  }
  return spots;
}

SpotKind? _spotKindFromString(String? s) {
  switch (s) {
    case 'l2_open_fold':
      return SpotKind.l2_open_fold;
    case 'l2_threebet_push':
      return SpotKind.l2_threebet_push;
    case 'l2_limped':
      return SpotKind.l2_limped;
    case 'l4_icm':
      return SpotKind.l4_icm;
  }
  return null;
}
