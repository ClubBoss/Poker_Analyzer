import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/push_fold_ev_service.dart';
import '../services/icm_push_ev_service.dart';
import '../models/saved_hand.dart';
import '../helpers/hand_utils.dart';
import '../utils/responsive.dart';
import '../theme/app_colors.dart';

class WeeklyProgressScreen extends StatelessWidget {
  const WeeklyProgressScreen({super.key});

  String? _handCode(SavedHand h) {
    if (h.playerCards.length <= h.heroIndex) return null;
    final cards = h.playerCards[h.heroIndex];
    if (cards.length < 2) return null;
    return handCode(
      '${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}',
    );
  }

  double? _ev(SavedHand h) {
    final act = heroAction(h);
    if (act == null) return null;
    var ev = act.ev;
    if (ev == null && act.action.toLowerCase() == 'push') {
      final code = _handCode(h);
      final stack = h.stackSizes[h.heroIndex];
      if (code != null && stack != null) {
        ev = computePushEV(
          heroBbStack: stack,
          bbCount: h.numberOfPlayers - 1,
          heroHand: code,
          anteBb: h.anteBb,
        );
      }
    }
    return ev;
  }

  double? _icm(SavedHand h, double? ev) {
    final act = heroAction(h);
    if (act == null) return null;
    var icm = act.icmEv;
    if (icm == null && act.action.toLowerCase() == 'push') {
      final code = _handCode(h);
      if (code != null && ev != null) {
        final stacks = [
          for (int i = 0; i < h.numberOfPlayers; i++) h.stackSizes[i] ?? 0,
        ];
        icm = computeIcmPushEV(
          chipStacksBb: stacks,
          heroIndex: h.heroIndex,
          heroHand: code,
          chipPushEv: ev,
        );
      }
    }
    return icm;
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final days = [for (int i = 0; i < 7; i++) start.add(Duration(days: i))];
    final Map<DateTime, List<SavedHand>> map = {for (final d in days) d: []};
    for (final h in hands) {
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      if (!day.isBefore(start) && !day.isAfter(days.last)) {
        map.putIfAbsent(day, () => []).add(h);
      }
    }

    final stats = <_DayStats>[];
    for (final d in days) {
      final list = map[d] ?? [];
      int total = 0;
      int correct = 0;
      double evSum = 0;
      int evCount = 0;
      double icmSum = 0;
      int icmCount = 0;
      for (final h in list) {
        final exp = h.expectedAction;
        final gto = h.gtoAction;
        if (exp != null && gto != null) {
          total++;
          if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) correct++;
        }
        final ev = _ev(h);
        if (ev != null) {
          evSum += ev;
          evCount++;
        }
        final icm = _icm(h, ev);
        if (icm != null) {
          icmSum += icm;
          icmCount++;
        }
      }
      final acc = total > 0 ? correct / total * 100 : 0;
      final evAvg = evCount > 0 ? evSum / evCount : 0;
      final icmAvg = icmCount > 0 ? icmSum / icmCount : 0;
      stats.add(_DayStats(d, acc, evAvg, icmAvg));
    }

    final accSpots = <FlSpot>[];
    final evSpots = <FlSpot>[];
    final icmSpots = <FlSpot>[];
    for (var i = 0; i < stats.length; i++) {
      accSpots.add(FlSpot(i.toDouble(), stats[i].accuracy));
      evSpots.add(FlSpot(i.toDouble(), stats[i].ev));
      icmSpots.add(FlSpot(i.toDouble(), stats[i].icm));
    }
    double minY = 0;
    double maxY = 100;
    for (final s in stats) {
      if (s.ev < minY) minY = s.ev;
      if (s.icm < minY) minY = s.icm;
      if (s.ev > maxY) maxY = s.ev;
      if (s.icm > maxY) maxY = s.icm;
    }
    final range = maxY - minY;
    final interval = range > 0 ? range / 5 : 1;
    final step = (stats.length / 6).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс за неделю'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: responsiveSize(context, 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Colors.white24, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.length)
                          return const SizedBox.shrink();
                        if (index % step != 0 && index != stats.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final d = stats[index].date;
                        return Text(
                          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        );
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
                lineBarsData: [
                  LineChartBarData(
                    spots: accSpots,
                    color: Colors.orangeAccent,
                    barWidth: 2,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: evSpots,
                    color: Colors.greenAccent,
                    barWidth: 2,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: icmSpots,
                    color: Colors.lightBlueAccent,
                    barWidth: 2,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final s in stats.reversed)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${s.date.day.toString().padLeft(2, '0')}.${s.date.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${s.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.ev.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.icm.toStringAsFixed(3),
                    style: const TextStyle(color: Colors.lightBlueAccent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayStats {
  final DateTime date;
  final double accuracy;
  final double ev;
  final double icm;
  _DayStats(this.date, this.accuracy, this.ev, this.icm);
}
