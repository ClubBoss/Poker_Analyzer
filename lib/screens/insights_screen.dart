import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_stats_service.dart';
import '../services/user_goal_engine.dart';
import '../theme/app_colors.dart';
import '../widgets/training_calendar_widget.dart';
import 'streak_calendar_screen.dart';
import '../widgets/mistake_summary_card.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/streak_trend_chart.dart';
import '../utils/responsive.dart';

enum _Mode { daily, weekly }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _Mode _mode = _Mode.daily;

  List<MapEntry<DateTime, int>> _hands(TrainingStatsService s) =>
      _mode == _Mode.daily ? s.handsDaily(7) : s.handsWeekly(6);
  List<MapEntry<DateTime, int>> _sessions(TrainingStatsService s) =>
      _mode == _Mode.daily ? s.sessionsDaily(7) : s.sessionsWeekly(6);
  List<MapEntry<DateTime, int>> _mistakes(TrainingStatsService s) =>
      _mode == _Mode.daily ? s.mistakesDaily(7) : s.mistakesWeekly(6);

  Widget _chart(List<MapEntry<DateTime, int>> data) {
    if (data.length < 2) return SizedBox(height: responsiveSize(context, 200));
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value.toDouble()));
    }
    final step = (data.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval:
                    data.map((e) => e.value).reduce((a, b) => a > b ? a : b) /
                        4,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
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
                  final d = data[i].key;
                  final label = _mode == _Mode.weekly
                      ? '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}'
                      : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                  return Text(
                    label,
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
              spots: spots,
              isCurved: false,
              color: AppColors.accent,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pie(UserGoalEngine g) {
    final goals = g.goals;
    if (goals.isEmpty) return SizedBox(height: responsiveSize(context, 200));
    final completed = goals.where((gg) => gg.completed).length;
    final sections = [
      PieChartSectionData(
        value: completed.toDouble(),
        color: Colors.green,
        radius: 80,
        title: goals.isNotEmpty
            ? '${(completed * 100 / goals.length).round()}%'
            : '0%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: (goals.length - completed).toDouble(),
        color: Colors.red,
        radius: 80,
        title: goals.isNotEmpty
            ? '${((goals.length - completed) * 100 / goals.length).round()}%'
            : '0%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 0,
          sections: sections,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final goals = context.watch<UserGoalEngine>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          SyncStatusIcon.of(context),
          ToggleButtons(
            isSelected: [_mode == _Mode.daily, _mode == _Mode.weekly],
            onPressed: (i) => setState(() => _mode = _Mode.values[i]),
            children: const [Text('День'), Text('Неделя')],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StreakCalendarScreen()),
              );
            },
            child: const TrainingCalendarWidget(),
          ),
          const SizedBox(height: 12),
          _chart(_hands(stats)),
          const SizedBox(height: 12),
          _chart(_mistakes(stats)),
          const SizedBox(height: 12),
          _chart(_sessions(stats)),
          const SizedBox(height: 12),
          const StreakTrendChart(),
          const SizedBox(height: 12),
          _pie(goals),
          const SizedBox(height: 12),
          const MistakeSummaryCard(),
        ],
      ),
    );
  }
}
