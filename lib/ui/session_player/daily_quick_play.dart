import 'dart:io';

import 'package:flutter/material.dart';

import 'mvs_player.dart';
import 'plan_progress.dart';
import 'plan_runner.dart';
import 'streak_store.dart';

class QuickDailyPlayPage extends StatefulWidget {
  final String planPath;
  final String bundleDir;
  const QuickDailyPlayPage({
    super.key,
    this.planPath = 'out/plan/play_plan_v1.json',
    this.bundleDir = 'dist/training_v1',
  });

  @override
  State<QuickDailyPlayPage> createState() => _QuickDailyPlayPageState();
}

class _QuickDailyPlayPageState extends State<QuickDailyPlayPage> {
  late Future<List<PlanSlice>> _futureSlices;
  PlanProgress _progress = const PlanProgress({});
  Streak _streak = const Streak(0, '');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _futureSlices = loadPlanSlices(planPath: widget.planPath);
    loadPlanProgress().then((p) {
      if (!mounted) return;
      setState(() => _progress = p);
    });
    loadStreak().then((s) {
      if (!mounted) return;
      setState(() => _streak = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily quick play')),
      body: FutureBuilder<List<PlanSlice>>(
        future: _futureSlices,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final slices = snap.data ?? [];
          PlanSlice? next;
          for (final s in slices) {
            if (_progress.done[s.id] != true) {
              next = s;
              break;
            }
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Streak: ${_streak.count} days'),
                Text('Next slice: ${next?.id ?? 'All done'}'),
                const SizedBox(height: 16),
                if (next == null)
                  const Expanded(
                    child: Center(child: Text('All slices completed')),
                  )
                else
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            try {
                              final spots = await loadSliceSpots(
                                bundleDir: Directory(widget.bundleDir),
                                slice: next!,
                              );
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    body: MvsSessionPlayer(spots: spots),
                                  ),
                                ),
                              );
                              final prog = markDone(_progress, next.id);
                              await savePlanProgress(prog);
                              final st = bumpIfNeeded(_streak);
                              await saveStreak(st);
                              if (!mounted) return;
                              setState(() {
                                _progress = prog;
                                _streak = st;
                              });
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: const Text('Play next slice'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
