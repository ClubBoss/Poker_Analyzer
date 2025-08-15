import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'decoders.dart';
import 'mvs_player.dart';
import 'models.dart';

class PlanSlice {
  final String id;
  final String kind;
  final String file;
  final int start;
  final int count;
  const PlanSlice({
    required this.id,
    required this.kind,
    required this.file,
    required this.start,
    required this.count,
  });
}

Future<List<PlanSlice>> loadPlanSlices({required String planPath}) async {
  final jsonStr = await File(planPath).readAsString();
  final root = jsonDecode(jsonStr);
  final items = root['items'] as List? ?? [];
  final slices = <PlanSlice>[];
  for (final raw in items) {
    if (raw is! Map) continue;
    final start = raw['start'];
    final count = raw['count'];
    slices.add(PlanSlice(
      id: '${raw['id']}',
      kind: '${raw['kind']}',
      file: '${raw['file']}',
      start: start is int ? start : int.tryParse('$start') ?? 0,
      count: count is int ? count : int.tryParse('$count') ?? 0,
    ));
  }
  return slices;
}

Future<List<UiSpot>> loadSliceSpots({
  required Directory bundleDir,
  required PlanSlice slice,
}) async {
  final path = slice.file.startsWith('/')
      ? slice.file
      : '${bundleDir.path}/${slice.file}';
  final jsonStr = await File(path).readAsString();
  List<UiSpot> spots = [];
  if (slice.kind == 'l3_session') {
    // TODO: replace with direct L3 decoder once schema stabilizes
    final root = jsonDecode(jsonStr);
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
            filePath = '${bundleDir.path}/$filePath';
          }
          final text = await File(filePath).readAsString();
          spots.addAll(decodeL2SessionJson(text));
        }
      }
    }
    if (spots.isEmpty) throw Exception('empty session');
  } else {
    switch (slice.kind) {
      case 'l2_session':
        spots = decodeL2SessionJson(jsonStr);
        break;
      case 'l4_session':
        spots = decodeL4IcmSessionJson(jsonStr);
        break;
      default:
        spots = [];
    }
  }
  var start = slice.start;
  if (start < 0) start = 0;
  if (start > spots.length) start = spots.length;
  var end = slice.count <= 0 ? spots.length : start + slice.count;
  if (end > spots.length) end = spots.length;
  return spots.sublist(start, end);
}

class PlayFromPlanPage extends StatefulWidget {
  final String planPath;
  final String bundleDir;
  const PlayFromPlanPage({super.key, required this.planPath, required this.bundleDir});

  @override
  State<PlayFromPlanPage> createState() => _PlayFromPlanPageState();
}

class _PlayFromPlanPageState extends State<PlayFromPlanPage> {
  late Future<List<PlanSlice>> _future;

  @override
  void initState() {
    super.initState();
    _future = loadPlanSlices(planPath: widget.planPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlanSlice>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final slices = snap.data ?? [];
        return ListView(
          children: [
            for (final slice in slices)
              ListTile(
                title: Text(slice.id),
                subtitle: Text('${slice.kind} · ${slice.count}'),
                trailing: TextButton(
                  onPressed: () async {
                    try {
                      final spots = await loadSliceSpots(
                        bundleDir: Directory(widget.bundleDir),
                        slice: slice,
                      );
                      if (spots.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No spots')),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: MvsSessionPlayer(spots: spots),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Play'),
                ),
              ),
          ],
        );
      },
    );
  }
}

