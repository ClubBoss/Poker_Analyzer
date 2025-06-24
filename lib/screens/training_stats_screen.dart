import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/training_pack_storage_service.dart';
import 'saved_hands_screen.dart';

class TrainingStatsScreen extends StatefulWidget {
  const TrainingStatsScreen({super.key});

  @override
  State<TrainingStatsScreen> createState() => _TrainingStatsScreenState();
}

class _TrainingStatsScreenState extends State<TrainingStatsScreen> {
  Map<String, int> _tagMistakes = {};
  Map<String, int> _positionTotal = {};
  Map<String, int> _positionCorrect = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gatherStats());
  }

  void _gatherStats() {
    final packs = context.read<TrainingPackStorageService>().packs;
    final Map<String, SavedHand> handIndex = {};
    for (final p in packs) {
      for (final h in p.hands) {
        handIndex[h.name] = h;
      }
    }

    final Map<String, int> tagMistakes = {};
    final Map<String, int> posTotal = {};
    final Map<String, int> posCorrect = {};

    for (final p in packs) {
      for (final session in p.history) {
        for (final task in session.tasks) {
          final hand = handIndex[task.question];
          final pos = hand?.heroPosition ?? 'Unknown';
          posTotal[pos] = (posTotal[pos] ?? 0) + 1;
          if (task.correct) {
            posCorrect[pos] = (posCorrect[pos] ?? 0) + 1;
          } else {
            for (final t in hand?.tags ?? <String>[]) {
              tagMistakes[t] = (tagMistakes[t] ?? 0) + 1;
            }
          }
        }
      }
    }

    setState(() {
      _tagMistakes = tagMistakes;
      _positionTotal = posTotal;
      _positionCorrect = posCorrect;
    });
  }

  Widget _buildStat(String label, String value,
      {VoidCallback? onTap, Color? color}) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: color ?? Colors.white70)),
          Text(value, style: TextStyle(color: color ?? Colors.white)),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }

  Widget _buildPositionRow(String pos, int correct, int total,
      {VoidCallback? onTap, Color? color}) {
    final acc = total > 0 ? (correct * 100 / total).round() : 0;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$pos — $acc% точность ($correct из $total верно)',
        style: TextStyle(color: color ?? Colors.white),
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }

  @override
  Widget build(BuildContext context) {
    final tagEntries = _tagMistakes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final posEntries = _positionTotal.keys
        .map((p) => MapEntry(p, _positionCorrect[p] ?? 0))
        .toList();

    posEntries.sort((a, b) {
      final ta = _positionTotal[a.key] ?? 0;
      final tb = _positionTotal[b.key] ?? 0;
      final accA = ta > 0 ? (a.value / ta) : 1.0;
      final accB = tb > 0 ? (b.value / tb) : 1.0;
      return accA.compareTo(accB);
    });

    final tagTop = tagEntries.take(5).toList();
    final bestTag = tagTop.isNotEmpty ? tagTop.last.key : null;
    final worstTag = tagTop.isNotEmpty ? tagTop.first.key : null;

    final posTop = posEntries.take(5).toList();
    String? bestPos;
    String? worstPos;
    double bestAcc = -1;
    double worstAcc = 2;
    for (final e in posTop) {
      final total = _positionTotal[e.key] ?? 0;
      final acc = total > 0 ? e.value / total : 1.0;
      if (acc > bestAcc) {
        bestAcc = acc;
        bestPos = e.key;
      }
      if (acc < worstAcc) {
        worstAcc = acc;
        worstPos = e.key;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Stats'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tagEntries.isNotEmpty) ...[
            const Text('Ошибки по тегам',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in tagTop)
              _buildStat(
                e.key,
                e.value.toString(),
                color: e.key == worstTag && worstTag != bestTag
                    ? Colors.red
                    : e.key == bestTag
                        ? Colors.green
                        : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialTag: e.key,
                        initialAccuracy: 'Только ошибки',
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
          if (posEntries.isNotEmpty) ...[
            const Text('Ошибки по позициям',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in posTop)
              _buildPositionRow(
                e.key,
                e.value,
                _positionTotal[e.key] ?? 0,
                color: e.key == worstPos && worstPos != bestPos
                    ? Colors.red
                    : e.key == bestPos
                        ? Colors.green
                        : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialPosition: e.key,
                        initialAccuracy: 'Только ошибки',
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
