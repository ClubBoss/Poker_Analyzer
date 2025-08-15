import 'dart:convert';
import 'dart:io';

import 'models.dart';

List<UiSpot> decodeL2SessionJson(String jsonStr) {
  final root = jsonDecode(jsonStr);
  final items = root['items'] as List? ?? [];
  final spots = <UiSpot>[];
  for (final raw in items) {
    if (raw is! Map) continue;
    final kind = raw['kind'];
    final SpotKind? spotKind;
    switch (kind) {
      case 'open_fold':
        spotKind = SpotKind.l2_open_fold;
        break;
      case 'threebet_push':
        spotKind = SpotKind.l2_threebet_push;
        break;
      case 'limped':
        spotKind = SpotKind.l2_limped;
        break;
      default:
        continue;
    }
    String? explain;
    final e = raw['explain'];
    if (e is String) {
      explain = e;
    } else {
      final w = raw['why'];
      if (w is String) explain = w;
    }
    spots.add(UiSpot(
      kind: spotKind,
      hand: '${raw['hand']}',
      pos: '${raw['pos']}',
      stack: '${raw['stack']}',
      action: '${raw['action']}',
      vsPos: raw['vsPos']?.toString(),
      limpers: raw['limpers']?.toString(),
      explain: explain,
    ));
  }
  return spots;
}

List<UiSpot> decodeL4IcmSessionJson(String jsonStr) {
  final root = jsonDecode(jsonStr);
  final items = root['items'] as List? ?? [];
  final spots = <UiSpot>[];
  for (final raw in items) {
    if (raw is! Map) continue;
    spots.add(UiSpot(
      kind: SpotKind.l4_icm,
      hand: '${raw['hand']}',
      pos: '${raw['heroPos']}',
      stack: '${raw['stackBb']}',
      action: '${raw['action']}',
      explain: raw['explain'] is String ? raw['explain'] as String : null,
    ));
  }
  return spots;
}

Future<List<UiSpot>> decodeL3SessionJson(String jsonStr,
    {required String baseDir}) async {
  final root = jsonDecode(jsonStr);
  final spots = <UiSpot>[];
  final inlineItems = root['inlineItems'];
  if (inlineItems is List) {
    for (final raw in inlineItems) {
      if (raw is! Map) continue;
      final kind = raw['kind'];
      SpotKind? spotKind;
      switch (kind) {
        case 'open_fold':
          spotKind = SpotKind.l2_open_fold;
          break;
        case 'threebet_push':
          spotKind = SpotKind.l2_threebet_push;
          break;
        case 'limped':
          spotKind = SpotKind.l2_limped;
          break;
      }
      if (spotKind == null) continue;
      String? explain;
      final e = raw['explain'];
      if (e is String) {
        explain = e;
      } else {
        final w = raw['why'];
        if (w is String) explain = w;
      }
      spots.add(UiSpot(
        kind: spotKind,
        hand: '${raw['hand']}',
        pos: '${raw['pos']}',
        stack: '${raw['stack']}',
        action: '${raw['action']}',
        vsPos: raw['vsPos']?.toString(),
        limpers: raw['limpers']?.toString(),
        explain: explain,
      ));
    }
  } else {
    final items = root['items'];
    if (items is List) {
      for (final entry in items) {
        String? filePath;
        if (entry is String) {
          filePath = entry;
        } else if (entry is Map) {
          final f = entry['file'];
          if (f is String) filePath = f;
        }
        if (filePath == null) continue;
        if (!filePath.startsWith('/') &&
            !(filePath.length > 1 && filePath[1] == ':')) {
          filePath = '$baseDir/$filePath';
        }
        final text = await File(filePath).readAsString();
        spots.addAll(decodeL2SessionJson(text));
      }
    }
  }
  if (spots.isEmpty) throw FormatException('empty l3 session');
  return spots;
}

String detectSessionKind(Map root) {
  final inlineItems = root['inlineItems'];
  if (inlineItems is List) return 'l3';
  final items = root['items'];
  if (items is List && items.isNotEmpty) {
    final isL3 =
        items.every((e) => e is String || (e is Map && e['file'] != null));
    if (isL3) return 'l3';
    final first = items.first;
    if (first is Map) {
      if (first.containsKey('kind')) return 'l2';
      if (first.containsKey('heroPos') && first.containsKey('stackBb')) {
        return 'l4';
      }
    }
  }
  return 'unknown';
}

