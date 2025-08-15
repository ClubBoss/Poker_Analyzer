import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'decoders.dart';
import 'mvs_player.dart';
import 'models.dart';
import 'plan_progress.dart';

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
  PlanProgress _progress = const PlanProgress({});
  final String _progressPath = 'out/plan/plan_progress_v1.json';
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = loadPlanSlices(planPath: widget.planPath);
    loadPlanProgress(path: _progressPath).then((p) {
      if (!mounted) return;
      setState(() => _progress = p);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan slices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final empty = const PlanProgress({});
              await savePlanProgress(empty, path: _progressPath);
              if (!mounted) return;
              setState(() => _progress = empty);
            },
            tooltip: 'Reset',
          ),
        ],
      ),
      body: FutureBuilder<List<PlanSlice>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final slices = snap.data ?? [];
          final q = _searchCtrl.text.trim().toLowerCase();
          bool matches(PlanSlice s) {
            final inText =
                q.isEmpty || s.id.toLowerCase().contains(q) || s.kind.toLowerCase().contains(q);
            final done = _progress.done[s.id] == true;
            final inStatus = _statusFilter == 'all' ||
                (_statusFilter == 'done' && done) ||
                (_statusFilter == 'undone' && !done);
            return inText && inStatus;
          }
          final filtered = [for (final s in slices) if (matches(s)) s];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search by id/kind...',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter'),
                        DropdownButton<String>(
                          value: _statusFilter,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _statusFilter = v);
                          },
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('all')),
                            DropdownMenuItem(value: 'undone', child: Text('undone')),
                            DropdownMenuItem(value: 'done', child: Text('done')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty || _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final deck = <UiSpot>[];
                            try {
                              for (final slice in filtered) {
                                final spots = await loadSliceSpots(
                                  bundleDir: Directory(widget.bundleDir),
                                  slice: slice,
                                );
                                deck.addAll(spots);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                              if (!mounted) return;
                              setState(() => _busy = false);
                              return;
                            }
                            if (deck.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No spots')),
                              );
                              if (!mounted) return;
                              setState(() => _busy = false);
                              return;
                            }
                            if (!context.mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    Scaffold(body: MvsSessionPlayer(spots: deck)),
                              ),
                            );
                            var updated = _progress;
                            for (final s in filtered) {
                              updated = markDone(updated, s.id, done: true);
                            }
                            await savePlanProgress(updated, path: _progressPath);
                            if (!mounted) return;
                            setState(() {
                              _progress = updated;
                              _busy = false;
                            });
                          },
                    child: const Text('Play filtered'),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const Expanded(
                  child: Center(child: Text('No slices match')),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      for (final slice in filtered)
                        ListTile(
                          title: Text(slice.id),
                          subtitle: Text('${slice.kind} · ${slice.count}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_progress.done[slice.id] == true)
                                const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              TextButton(
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
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => Scaffold(
                                          body: MvsSessionPlayer(spots: spots),
                                        ),
                                      ),
                                    );
                                    final updated =
                                        markDone(_progress, slice.id, done: true);
                                    await savePlanProgress(updated, path: _progressPath);
                                    if (!mounted) return;
                                    setState(() => _progress = updated);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                child: const Text('Play'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

