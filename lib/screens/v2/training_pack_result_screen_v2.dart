import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../theme/app_colors.dart';
import 'training_pack_play_screen.dart';

class TrainingPackResultScreenV2 extends StatelessWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final Map<String, String> results;
  const TrainingPackResultScreenV2({
    super.key,
    required this.template,
    required this.results,
    TrainingPackTemplate? original,
  }) : original = original ?? template;

  String? _expected(TrainingPackSpot s) {
    final eval = s.evalResult?.expectedAction;
    if (eval != null && eval.isNotEmpty) return eval;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex) return a.action;
    }
    return null;
  }

  double? _actionEv(TrainingPackSpot s, String action) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot s) {
    double? best;
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best!, a.ev!);
      }
    }
    return best;
  }

  Future<void> _repeat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tpl_seq_${original.id}');
    await prefs.remove('tpl_prog_${original.id}');
    await prefs.remove('tpl_res_${original.id}');
    await prefs.remove('tpl_ts_${original.id}');
    if (original.targetStreet != null) {
      await prefs.remove('tpl_street_${original.id}');
    }
    if (original.focusHandTypes.isNotEmpty) {
      await prefs.remove('tpl_hand_${original.id}');
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: template,
          original: original,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = template.spots;
    int correct = 0;
    final diffs = <double>[];
    final mistakes = <TrainingPackSpot>[];
    for (final s in spots) {
      final ans = results[s.id];
      final exp = _expected(s);
      if (ans == null || exp == null) continue;
      final heroEv = _actionEv(s, ans);
      final bestEv = _bestEv(s);
      if (heroEv != null && bestEv != null) diffs.add(heroEv - bestEv);
      if (ans.toLowerCase() == exp.toLowerCase()) {
        correct++;
      } else {
        mistakes.add(s);
      }
    }
    final total = spots.length;
    final accuracy = total == 0 ? 0 : correct * 100 / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Результаты')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Точность: ${accuracy.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Верно: $correct / $total',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            Text('Ошибки: ${total - correct}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            if (diffs.length >= 2) ...[
              const SizedBox(height: 16),
              _EvDiffChart(diffs: diffs),
            ],
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Ошибки:',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: mistakes.length,
                  itemBuilder: (context, i) {
                    final s = mistakes[i];
                    final board = s.hand.board.join(' ');
                    final hero = s.hand.heroCards;
                    final best = _expected(s) ?? '';
                    final ans = results[s.id] ?? '';
                    final heroEv = _actionEv(s, ans);
                    final bestEv = _bestEv(s);
                    final diff = heroEv != null && bestEv != null
                        ? heroEv - bestEv
                        : null;
                    final diffText = diff == null
                        ? '--'
                        : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          board.isEmpty ? '(Preflop)' : board,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hero: $hero',
                                style: const TextStyle(color: Colors.white70)),
                            Text('Ваше действие: $ans',
                                style: const TextStyle(color: Colors.redAccent)),
                            Text('Лучшее действие: $best',
                                style:
                                    const TextStyle(color: Colors.greenAccent)),
                            Text('EV diff: $diffText',
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
            ElevatedButton(
              onPressed: () => _repeat(context),
              child: const Text('Повторить тренировку'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvDiffChart extends StatelessWidget {
  final List<double> diffs;
  const _EvDiffChart({required this.diffs});

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) return const SizedBox.shrink();
    final limit = diffs.map((e) => e.abs()).reduce(max);
    final maxY = limit == 0 ? 1.0 : limit;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < diffs.length; i++) {
      final d = diffs[i];
      final color = d >= 0 ? Colors.greenAccent : Colors.redAccent;
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: d,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ]),
      );
    }
    final interval = maxY / 5;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: -maxY,
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= diffs.length) {
                    return const SizedBox.shrink();
                  }
                  return Text('${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.white24),
              bottom: BorderSide(color: Colors.white24),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }
}
