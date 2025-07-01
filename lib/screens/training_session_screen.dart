import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_session_service.dart';
import '../widgets/spot_quiz_widget.dart';
import 'session_result_screen.dart';

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
  const TrainingSessionScreen({super.key, this.onSessionEnd});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  static final _EndlessStats _endlessStats = _EndlessStats();
  String? _selected;
  bool? _correct;
  Timer? _timer;
  bool _continue = false;

  @override
  void initState() {
    super.initState();
    if (widget.onSessionEnd != null && _endlessStats.total == 0 && _endlessStats.elapsed == Duration.zero) {
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

  void _next(service) {
    final next = service.nextSpot();
    if (next == null) {
      if (widget.onSessionEnd != null) {
        _endlessStats.addDuration(service.elapsedTime);
        _continue = true;
        Navigator.pop(context);
        widget.onSessionEnd!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionResultScreen(
              total: service.totalCount,
              correct: service.correctCount,
              elapsed: service.elapsedTime,
              authorPreview: service.session?.authorPreview ?? false,
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final service = context.read<TrainingSessionService>();
        if (service.session?.completedAt != null) return true;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title:
                const Text('Exit training? Unsaved progress will be lost.'),
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
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        '${(service.session?.index ?? 0) + 1} / ${service.totalCount}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elapsed: ${_format(service.elapsedTime)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: SpotQuizWidget(spot: spot)),
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
                          for (final a in ['fold', 'call', 'raise', 'check', 'bet'])
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
                        _correct! ? 'Верно!' : 'Неверно. Надо ${expected ?? '-'}',
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
        );
      },
    ),
  );
  }
}
