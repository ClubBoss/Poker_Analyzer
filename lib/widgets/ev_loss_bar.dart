import 'package:flutter/material.dart';
import '../models/training_spot.dart';
import '../helpers/poker_street_helper.dart';
import '../models/action_entry.dart';

class EvLossBar extends StatelessWidget {
  final TrainingSpot spot;
  final int playbackIndex;
  final double? totalEvLoss;

  const EvLossBar({
    super.key,
    required this.spot,
    required this.playbackIndex,
    this.totalEvLoss,
  });

  double? _ev(ActionEntry a) {
    final d = a as dynamic;
    if (d.currentEv != null) return (d.currentEv as num).toDouble();
    if (d.ev != null) return (d.ev as num).toDouble();
    if (d.evAfter != null) return (d.evAfter as num).toDouble();
    return null;
  }

  List<double> _deltas() {
    final acts = spot.actions;
    final result = <double>[];
    double prev = _ev(acts.first) ?? 0;
    for (final a in acts) {
      final cur = _ev(a) ?? prev;
      result.add(prev - cur);
      prev = cur;
    }
    if (result.every((e) => e.abs() < 1e-6) && totalEvLoss != null) {
      final idx = acts.indexWhere((a) => a.playerIndex == spot.heroIndex);
      if (idx >= 0) result[idx] = totalEvLoss!;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final acts = spot.actions;
    if (acts.isEmpty) return const SizedBox.shrink();
    final deltas = _deltas();
    final loss = deltas.where((d) => d > 0).fold<double>(0, (a, b) => a + b);
    final border = loss > 0.5 ? Border.all(color: Colors.red) : null;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: border,
        borderRadius: BorderRadius.circular(4),
      ),
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final unit = constraints.maxWidth / acts.length;
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 1,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                  ),
                ),
              ),
              for (int i = 0; i < acts.length; i++)
                Positioned(
                  left: unit * i,
                  width: unit,
                  top: 0,
                  bottom: 0,
                  child: Tooltip(
                    message:
                        'Street: ${streetName(acts[i].street)} • EV loss: ${deltas[i].toStringAsFixed(1)} bb',
                    child: Container(
                      color: (deltas[i] > 0 ? Colors.red : Colors.green)
                          .withValues(alpha: i < playbackIndex ? 1 : 0.3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
