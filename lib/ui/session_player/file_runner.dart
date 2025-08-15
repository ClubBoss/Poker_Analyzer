import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'decoders.dart';
import 'mvs_player.dart';
import 'models.dart';

class PlayFromFilePage extends StatelessWidget {
  final String path;
  const PlayFromFilePage({super.key, required this.path});

  Future<List<UiSpot>> _load() async {
    final jsonStr = await File(path).readAsString();
    final root = jsonDecode(jsonStr);
    final items = root['items'];
    final inlineItems = root['inlineItems'];
    final isL3 = inlineItems is List ||
        (items is List &&
            items.every((e) =>
                e is String || (e is Map && e['file'] is String)));
    if (isL3) {
      return _decodeL3(jsonStr, baseDir: File(path).parent.path);
    }
    final kind = detectSessionKind(root);
    switch (kind) {
      case 'l2':
        return decodeL2SessionJson(jsonStr);
      case 'l4':
        return decodeL4IcmSessionJson(jsonStr);
      default:
        throw Exception('unknown session kind');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UiSpot>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final spots = snap.data ?? [];
        return MvsSessionPlayer(spots: spots);
      },
    );
  }
}

Future<List<UiSpot>> _decodeL3(String jsonStr,
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
  if (spots.isEmpty) throw Exception('empty session');
  return spots;
}

