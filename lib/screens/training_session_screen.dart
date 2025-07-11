import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_session_service.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/style_hint_bar.dart';
import '../widgets/stack_range_bar.dart';
import 'session_result_screen.dart';
import '../services/training_pack_stats_service.dart';
import '../services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_session.dart';

class _EndlessStats {
  int total = 0;
  int correct = 0;
  Duration elapsed = Duration.zero;
  void add(bool ok) {
    total += 1;
    if (ok) correct += 1;
  }

  void addDuration(Duration d) {
    elapsed += d;
  }

  double get accuracy => total == 0 ? 0 : correct / total;

  void reset() {
    total = 0;
    correct = 0;
    elapsed = Duration.zero;
  }
}


class TrainingSessionScreen extends StatefulWidget {
  final VoidCallback? onSessionEnd;
  final TrainingSession? session;
  const TrainingSessionScreen({super.key, this.onSessionEnd, this.session});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  static final _EndlessStats _endlessStats = _EndlessStats();
  String? _selected;
  bool? _correct;
  Timer? _timer;
  bool _continue = false;
  bool _summaryShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.onSessionEnd != null &&
        _endlessStats.total == 0 &&
        _endlessStats.elapsed == Duration.zero) {
      _endlessStats.reset();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.onSessionEnd != null && !_continue) {
      _endlessStats.reset();
    }
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _expectedAction(spot) {
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }

  void _choose(String action, service, spot) {
    if (_selected != null) return;
    final expected = _expectedAction(spot);
    final ok =
        expected != null && action.toLowerCase() == expected.toLowerCase();
    service.submitResult(spot.id, action, ok);
    if (widget.onSessionEnd != null) _endlessStats.add(ok);
    setState(() {
      _selected = action;
      _correct = ok;
    });
  }

  Future<void> _next(service) async {
    final next = service.nextSpot();
    if (!mounted) return;
    if (next == null) {
      if (widget.onSessionEnd != null) {
        _endlessStats.addDuration(service.elapsedTime);
        _continue = true;
        Navigator.pop(context);
        widget.onSessionEnd!();
      } else {
        final restart = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restart Pack'),
              ),
            ],
          ),
        );
        if (restart == true) {
          service.session?.index = 0;
          service.session?.completedAt = null;
          setState(() {
            _selected = null;
            _correct = null;
          });
        } else {
          _summaryShown = true;
          _showSummary(service);
        }
      }
    } else {
      setState(() {
        _selected = null;
        _correct = null;
      });
    }
  }

  void _prev(service) {
    final prev = service.prevSpot();
    if (prev != null) {
      final res = service.results[prev.id];
      setState(() {
        if (res != null) {
          _selected = '';
          _correct = res;
        } else {
          _selected = null;
          _correct = null;
        }
      });
    }
  }

  Future<void> _showSummary(TrainingSessionService service) async {
    final tpl = service.template;
    if (tpl != null) {
      final correct = service.correctCount;
      final total = service.totalCount;
      final acc = total == 0 ? 0.0 : correct / total;
      final totalSpots = tpl.spots.length;
      final evAfter = totalSpots == 0 ? 0.0 : tpl.evCovered * 100 / totalSpots;
      final icmAfter =
          totalSpots == 0 ? 0.0 : tpl.icmCovered * 100 / totalSpots;
      unawaited(TrainingPackStatsService.recordSession(
        tpl.id,
        correct,
        total,
        preEvPct: service.preEvPct,
        preIcmPct: service.preIcmPct,
        postEvPct: evAfter,
        postIcmPct: icmAfter,
        evSum: 0,
        icmSum: 0,
      ));
      if (acc >= 0.8) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('completed_tpl_${tpl.id}', true);
        final cloud = context.read<CloudSyncService?>();
        if (cloud != null) {
          unawaited(cloud.save('completed_tpl_${tpl.id}', '1'));
        }
      }
    }
    await service.complete(context);
  }

  void _showEndlessSummary() {
    final service = context.read<TrainingSessionService>();
    _endlessStats.addDuration(service.elapsedTime);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionResultScreen(
          total: _endlessStats.total,
          correct: _endlessStats.correct,
          elapsed: _endlessStats.elapsed,
          authorPreview: false,
        ),
      ),
    );
    _endlessStats.reset();
  }

  Widget _progressBar(TrainingSessionService service) {
    final total = service.template?.spots.length ?? 0;
    if (total == 0) return const SizedBox(height: 4);
    final index = service.session?.index ?? 0;
    final correct = service.results.values.where((e) => e).length;
    final incorrect = service.results.values.where((e) => !e).length;
    final remaining = (total - index).clamp(0, total);
    final segments = <Widget>[];
    if (correct > 0) {
      segments.add(Expanded(
          flex: correct,
          child: Container(height: 4, color: Colors.green)));
    }
    if (incorrect > 0) {
      segments.add(Expanded(
          flex: incorrect,
          child: Container(height: 4, color: Colors.red)));
    }
    if (remaining > 0) {
      segments.add(Expanded(
          flex: remaining,
          child: Container(height: 4, color: Colors.grey)));
    }
    return Row(children: segments);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final service = context.read<TrainingSessionService>();
        if (service.session?.completedAt != null) return true;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit training? Unsaved progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Consumer<TrainingSessionService>(
        builder: (context, service, _) {
          if (!_summaryShown &&
              service.session != null &&
              service.template != null &&
              service.session!.index >= service.template!.spots.length) {
            _summaryShown = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _showSummary(service));
          }
          final spot = service.currentSpot;
          if (spot == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF1B1C1E),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final expected = _expectedAction(spot);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Training'),
              actions: [
                IconButton(
                  onPressed: service.isPaused ? service.resume : service.pause,
                  icon: Icon(service.isPaused ? Icons.play_arrow : Icons.pause),
                )
              ],
            ),
            backgroundColor: const Color(0xFF1B1C1E),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (service.session != null &&
                          service.template != null) ...[
                        Text(
                          service.template!.name,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        _progressBar(service),
                        const SizedBox(height: 4),
                        Text(
                          'Accuracy ${(service.results.isEmpty ? 0 : service.results.values.where((e) => e).length * 100 / service.results.length).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EV ${service.evAverage.toStringAsFixed(2)} • ICM ${service.icmAverage.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.session!.index + 1} / ${service.template!.spots.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Elapsed: ${_format(service.elapsedTime)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      const StyleHintBar(),
                      const StackRangeBar(),
                      Expanded(child: SpotQuizWidget(spot: spot)),
                      if (service.focusHandTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final g in service.focusHandTypes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: service.handGoalTotal[
                                                          g.label] !=
                                                      null &&
                                                  service.handGoalTotal[
                                                          g.label]! >
                                                      0
                                              ? (service.handGoalCount[g.label]
                                                          ?.clamp(
                                                              0,
                                                              service.handGoalTotal[
                                                                  g.label]!) ??
                                                      0) /
                                                  service
                                                      .handGoalTotal[g.label]!
                                              : 0,
                                          color: Colors.purpleAccent,
                                          backgroundColor: Colors.purpleAccent
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${g.label} ${service.handGoalCount[g.label] ?? 0}/${service.handGoalTotal[g.label] ?? 0}',
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (service.isPaused) ...[
                        const SizedBox(height: 16),
                        const Text('Сессия на паузе',
                            style: TextStyle(color: Colors.white54)),
                      ] else if (_selected == null) ...[
                        const SizedBox(height: 16),
                        const Text('Ваше действие?',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final a in [
                              'fold',
                              'call',
                              'raise',
                              'check',
                              'bet'
                            ])
                              ElevatedButton(
                                onPressed: () => _choose(a, service, spot),
                                child: Text(a.toUpperCase()),
                              ),
                          ],
                        ),
                        if (service.session?.index != null &&
                            service.session!.index > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: () => _prev(service),
                                child: const Text('Prev'),
                              ),
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Text(
                          _correct!
                              ? 'Верно!'
                              : 'Неверно. Надо ${expected ?? '-'}',
                          style: TextStyle(
                            color: _correct! ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (service.session?.index != null &&
                                service.session!.index > 0)
                              ElevatedButton(
                                onPressed: () => _prev(service),
                                child: const Text('Prev'),
                              ),
                            ElevatedButton(
                              onPressed: () => _next(service),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onSessionEnd != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Total: ${_endlessStats.total}  ${(_endlessStats.accuracy * 100).toStringAsFixed(0)}%  ${_format(_endlessStats.elapsed + service.elapsedTime)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: widget.onSessionEnd != null
                ? FloatingActionButton(
                    heroTag: 'stopDrillFab',
                    tooltip: 'Stop Drill & show summary',
                    child: const Icon(Icons.stop),
                    onPressed: _showEndlessSummary,
                  )
                : null,
          );
        },
      ),
    );
  }
}
