// Example:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => Scaffold(body: MvsSessionPlayer(spots: demoSpots())),
// ));

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'result_summary.dart';

class MvsSessionPlayer extends StatefulWidget {
  final List<UiSpot> spots;
  const MvsSessionPlayer({super.key, required this.spots});

  @override
  State<MvsSessionPlayer> createState() => _MvsSessionPlayerState();
}

class _MvsSessionPlayerState extends State<MvsSessionPlayer> {
  late List<UiSpot> _spots;
  int _index = 0;
  final _answers = <UiAnswer>[];
  final _timer = Stopwatch();
  final _focusNode = FocusNode();
  Timer? _ticker;
  Timer? _autoNextTimer;
  String? _chosen;
  bool _showExplain = false;
  bool _autoNext = false;

  @override
  void initState() {
    super.initState();
    _spots = widget.spots;
    _timer.start();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoNextTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker =
        Timer.periodic(const Duration(milliseconds: 200), (_) => setState(() {}));
  }

  void _onAction(String action) {
    if (_chosen != null) return;
    _timer.stop();
    _ticker?.cancel();
    final spot = _spots[_index];
    final correct = action == spot.action;
    setState(() {
      _chosen = action;
      _answers.add(UiAnswer(
        correct: correct,
        expected: spot.action,
        chosen: action,
        elapsed: _timer.elapsed,
      ));
    });
    if (correct && _autoNext) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_chosen != null && _answers[_index].correct) _next();
      });
    }
  }

  void _next() {
    _autoNextTimer?.cancel();
    if (_index + 1 >= _spots.length) {
      setState(() => _index++);
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
    });
    _startTicker();
    _focusNode.requestFocus();
  }

  void _restart(List<UiSpot> spots) {
    _autoNextTimer?.cancel();
    setState(() {
      _spots = spots;
      _index = 0;
      _answers.clear();
      _chosen = null;
      _showExplain = false;
      _timer
        ..reset()
        ..start();
    });
    _startTicker();
    _focusNode.requestFocus();
  }

  void _replayErrors() {
    final wrong = <UiSpot>[];
    for (var i = 0; i < _spots.length; i++) {
      if (!_answers[i].correct) wrong.add(_spots[i]);
    }
    if (wrong.isEmpty) {
      _restart(widget.spots);
    } else {
      _restart(wrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_index >= _spots.length) {
      child = ResultSummaryView(
        key: const ValueKey('summary'),
        spots: _spots,
        answers: _answers,
        onReplayErrors: _replayErrors,
        onRestart: () => _restart(widget.spots),
      );
    } else {
      child = _buildSpotCard(_spots[_index]);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  Widget _buildSpotCard(UiSpot spot) {
    final actions = _actionsFor(spot.kind);
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.keyA) {
          setState(() => _autoNext = !_autoNext);
          return;
        }
        if (_chosen == null) {
          if (event.logicalKey == LogicalKeyboardKey.digit1 &&
              actions.length > 0) {
            _onAction(actions[0]);
          } else if (event.logicalKey == LogicalKeyboardKey.digit2 &&
              actions.length > 1) {
            _onAction(actions[1]);
          } else if (event.logicalKey == LogicalKeyboardKey.digit3 &&
              actions.length > 2) {
            _onAction(actions[2]);
          }
        } else {
          if (event.logicalKey == LogicalKeyboardKey.keyH) {
            setState(() => _showExplain = !_showExplain);
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _next();
          }
        }
      },
      child: Padding(
        key: ValueKey('spot$_index'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spot ${_index + 1}/${_spots.length}'),
            Text(
                't=${(_timer.elapsedMilliseconds / 1000).toStringAsFixed(1)}s'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (_index + 1) / _spots.length,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Auto-next'),
            Switch(
              value: _autoNext,
              onChanged: (v) => setState(() => _autoNext = v),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  Text(
                    spot.hand,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSubTitle(spot),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...actions.map((a) => _buildActionButton(a, spot)),
                  if (_chosen != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _answers[_index].correct
                          ? 'Correct!'
                          : 'Try again next time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _answers[_index].correct
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showExplain = !_showExplain),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Why?'),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(spot.explain ?? 'No explanation'),
                      ),
                      crossFadeState: _showExplain
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _next,
                      child: const Text('Next'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubTitle(UiSpot spot) {
    final parts = <String>[spot.pos];
    if (spot.vsPos != null) parts.add('vs ${spot.vsPos}');
    if (spot.limpers != null) parts.add('limpers ${spot.limpers}');
    parts.add(spot.stack);
    return parts.join(' • ');
  }

  List<String> _actionsFor(SpotKind kind) {
    switch (kind) {
      case SpotKind.l2_open_fold:
        return ['open', 'fold'];
      case SpotKind.l2_threebet_push:
        return ['jam', 'fold'];
      case SpotKind.l2_limped:
        return ['iso', 'overlimp', 'fold'];
      case SpotKind.l4_icm:
        return ['jam', 'fold'];
    }
  }

  Widget _buildActionButton(String action, UiSpot spot) {
    final correct = action == spot.action;
    Color? color;
    if (_chosen != null) {
      if (action == _chosen) {
        color = correct ? Colors.green : Colors.red;
      } else if (correct) {
        color = Colors.green;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: _chosen == null ? () => _onAction(action) : null,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        child: Text(action),
      ),
    );
  }
}
