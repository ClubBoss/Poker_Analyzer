// Example:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => Scaffold(body: MvsSessionPlayer(spots: demoSpots())),
// ));

import 'package:flutter/material.dart';

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
  String? _chosen;

  @override
  void initState() {
    super.initState();
    _spots = widget.spots;
    _timer.start();
  }

  void _onAction(String action) {
    if (_chosen != null) return;
    _timer.stop();
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
  }

  void _next() {
    if (_index + 1 >= _spots.length) {
      setState(() => _index++);
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _timer..reset()..start();
    });
  }

  void _restart(List<UiSpot> spots) {
    setState(() {
      _spots = spots;
      _index = 0;
      _answers.clear();
      _chosen = null;
      _timer..reset()..start();
    });
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
    return Padding(
      key: ValueKey('spot$_index'),
      padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _next,
              child: const Text('Далее'),
            ),
          ],
        ],
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
