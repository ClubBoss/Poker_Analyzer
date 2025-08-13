import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/saved_hand.dart';
import '../helpers/hand_utils.dart';
import '../services/push_fold_ev_service.dart';
import '../services/icm_push_ev_service.dart';
import 'common/animated_line_chart.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class EvIcmChart extends StatelessWidget {
  final List<SavedHand> hands;
  const EvIcmChart({super.key, required this.hands});

  String? _handCode(SavedHand h) {
    if (h.playerCards.length <= h.heroIndex) return null;
    final cards = h.playerCards[h.heroIndex];
    if (cards.length < 2) return null;
    return handCode(
        '${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}');
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
          for (int i = 0; i < h.numberOfPlayers; i++) h.stackSizes[i] ?? 0
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
    final data = [...hands]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    if (data.length < 2) return const SizedBox.shrink();
    final evs = <double>[];
    final icms = <double>[];
    for (final h in data) {
      final ev = _ev(h) ?? 0;
      evs.add(ev);
      icms.add(_icm(h, ev) ?? 0);
    }
    final spotsEv = <FlSpot>[];
    final spotsIcm = <FlSpot>[];
    double maxAbs = 0;
    for (var i = 0; i < evs.length; i++) {
      final ev = evs[i];
      final icm = icms[i];
      if (ev.abs() > maxAbs) maxAbs = ev.abs();
      if (icm.abs() > maxAbs) maxAbs = icm.abs();
      spotsEv.add(FlSpot(i.toDouble(), ev));
      spotsIcm.add(FlSpot(i.toDouble(), icm));
    }
    if (maxAbs < 0.1) maxAbs = 0.1;
    final interval = (maxAbs / 5).ceilToDouble();
    final step = (data.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: -maxAbs,
          maxY: maxAbs,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
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
              spots: spotsEv,
              color: AppColors.evPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsIcm,
              color: AppColors.icmPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
