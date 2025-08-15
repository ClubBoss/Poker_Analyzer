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
  final resolvedPath = slice.file.startsWith('/')
      ? slice.file
      : '${bundleDir.path}/${slice.file}';
  final jsonStr = await File(resolvedPath).readAsString();
  List<UiSpot> spots;
  switch (slice.kind) {
    case 'l2_session':
      spots = decodeL2SessionJson(jsonStr);
      break;
    case 'l3_session':
      spots = await decodeL3SessionJson(jsonStr,
          baseDir: File(resolvedPath).parent.path);
      break;
    case 'l4_session':
      spots = decodeL4IcmSessionJson(jsonStr);
      break;
    default:
      spots = [];
  }
  var start = slice.start;
  if (start < 0) start = 0;
  if (start > spots.length) start = spots.length;
  var end = slice.count <= 0 ? spots.length : start + slice.count;
  if (end > spots.length) end = spots.length;
  final sub = spots.sublist(start, end);
  if (sub.isEmpty) throw Exception('empty slice');
  return sub;
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

