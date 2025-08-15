import 'dart:convert';

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
    spots.add(UiSpot(
      kind: spotKind,
      hand: '${raw['hand']}',
      pos: '${raw['pos']}',
      stack: '${raw['stack']}',
      action: '${raw['action']}',
      vsPos: raw['vsPos']?.toString(),
      limpers: raw['limpers']?.toString(),
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
    ));
  }
  return spots;
}

String detectSessionKind(Map root) {
  final items = root['items'];
  if (items is List && items.isNotEmpty) {
    final first = items.first;
    if (first is Map) {
      if (first.containsKey('kind')) return 'l2';
      if (first.containsKey('heroPos') && first.containsKey('stackBb')) return 'l4';
    }
  }
  return 'unknown';
}

