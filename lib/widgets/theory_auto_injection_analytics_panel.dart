import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/theory_auto_injection_logger_service.dart';
import '../services/mini_lesson_library_service.dart';

/// Displays analytics for automatic theory injections.
class TheoryAutoInjectionAnalyticsPanel extends StatefulWidget {
  const TheoryAutoInjectionAnalyticsPanel({super.key});

  @override
  State<TheoryAutoInjectionAnalyticsPanel> createState() =>
      _TheoryAutoInjectionAnalyticsPanelState();
}

class _TheoryAutoInjectionAnalyticsPanelState
    extends State<TheoryAutoInjectionAnalyticsPanel> {
  bool _loading = true;
  late List<_DailyData> _daily;
  late List<_LessonCount> _topLessons;

  bool _dailyExpanded = true;
  bool _lessonsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final logger = TheoryAutoInjectionLoggerService.instance;
    final dailyMap = await logger.getDailyInjectionCounts(days: 7);
    final topMap = await logger.getTopLessonInjections(limit: 5);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    _daily = [
      for (int i = 0; i < 7; i++)
        _DailyData(
          start.add(Duration(days: i)),
          dailyMap[start
                  .add(Duration(days: i))
                  .toIso8601String()
                  .split('T')
                  .first] ??
              0,
        )
    ];

    await MiniLessonLibraryService.instance.loadAll();
    _topLessons = [
      for (final e in topMap.entries)
        _LessonCount(
          id: e.key,
          count: e.value,
          title:
              MiniLessonLibraryService.instance.getById(e.key)?.resolvedTitle ??
                  e.key,
        )
    ];

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDailyChart(context),
        const SizedBox(height: 16),
        _buildTopLessonsChart(context),
      ],
    );
  }

  Widget _buildDailyChart(BuildContext context) {
    final maxY = _daily.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    final spots = [
      for (int i = 0; i < _daily.length; i++)
        FlSpot(i.toDouble(), _daily[i].count.toDouble())
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: _dailyExpanded,
        onExpansionChanged: (v) => setState(() => _dailyExpanded = v),
        title: const Text(
          'Daily injections',
          style: TextStyle(color: Colors.white),
        ),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        textColor: Colors.white,
        childrenPadding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (maxY < 1 ? 1 : maxY).toDouble(),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _daily.length) {
                          return const SizedBox.shrink();
                        }
                        final d = _daily[index].date;
                        return Text(
                          '${d.month}/${d.day}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: Theme.of(context).colorScheme.secondary,
                    barWidth: 2,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLessonsChart(BuildContext context) {
    final maxY = _topLessons.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < _topLessons.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _topLessons[i].count.toDouble(),
              width: 16,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: _lessonsExpanded,
        onExpansionChanged: (v) => setState(() => _lessonsExpanded = v),
        title: const Text(
          'Top lessons',
          style: TextStyle(color: Colors.white),
        ),
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        textColor: Colors.white,
        childrenPadding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: (maxY < 1 ? 1 : maxY).toDouble(),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _topLessons.length) {
                          return const SizedBox.shrink();
                        }
                        final title = _topLessons[index].title;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            title.length > 10 ? '${title.substring(0, 10)}…' : title,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyData {
  final DateTime date;
  final int count;
  const _DailyData(this.date, this.count);
}

class _LessonCount {
  final String id;
  final int count;
  final String title;
  const _LessonCount({
    required this.id,
    required this.count,
    required this.title,
  });
}

