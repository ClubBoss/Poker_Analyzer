import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:math';

import '../services/goals_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../models/summary_result.dart';
import '../theme/app_colors.dart';
import '../helpers/poker_street_helper.dart';
import '../widgets/mistake_heatmap.dart';
import 'goals_history_screen.dart';
import 'achievements_screen.dart';
import 'drill_history_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  SummaryResult? _summary;
  List<FlSpot> _streakSpots = [];
  List<MapEntry<DateTime, int>> _mistakesPerDay = [];
  Map<String, Map<String, int>> _heatmapData = {};
  bool _goalCompleted = false;
  bool _allGoalsCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gatherData());
    final goals = context.read<GoalsService>();
    _goalCompleted = goals.anyCompleted;
    _allGoalsCompleted = goals.goals.every((g) => g.completed);
    goals.addListener(_onGoalsChanged);
  }

  void _gatherData() {
    final manager = context.read<SavedHandManagerService>();
    final executor = EvaluationExecutorService();
    final hands = manager.hands;
    final summary = executor.summarizeHands(hands);

    final sorted = [...hands]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    int streak = 0;
    final counts = <DateTime, int>{};
    final heatmap = {
      for (final p in ['BB', 'SB', 'BTN', 'CO', 'MP', 'UTG'])
        p: {for (final s in kStreetNames) s: 0}
    };
    for (var i = 0; i < sorted.length; i++) {
      final h = sorted[i];
      final correct = h.expectedAction != null &&
          h.gtoAction != null &&
          h.expectedAction!.trim().toLowerCase() ==
              h.gtoAction!.trim().toLowerCase();
      streak = correct ? streak + 1 : 0;
      spots.add(FlSpot(i.toDouble(), streak.toDouble()));
      if (!correct) {
        final day = DateTime(h.date.year, h.date.month, h.date.day);
        counts.update(day, (v) => v + 1, ifAbsent: () => 1);
        final pos = h.heroPosition;
        final street = streetName(h.boardStreet);
        if (heatmap.containsKey(pos)) {
          heatmap[pos]![street] = heatmap[pos]![street]! + 1;
        }
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = entries.where((e) => e.key.isAfter(cutoff)).toList();

    setState(() {
      _summary = summary;
      _streakSpots = spots;
      _mistakesPerDay = recent;
      _heatmapData = heatmap;
    });
  }

  void _onGoalsChanged() {
    final service = context.read<GoalsService>();
    final completed = service.anyCompleted;
    final all = service.goals.every((g) => g.completed);
    if (completed != _goalCompleted || all != _allGoalsCompleted) {
      setState(() {
        _goalCompleted = completed;
        _allGoalsCompleted = all;
      });
    }
  }

  Widget _buildPieChart() {
    final summary = _summary;
    if (summary == null || summary.totalHands == 0) {
      return const SizedBox.shrink();
    }

    final dataMap = {
      'Верно': summary.correct.toDouble(),
      'Ошибка': summary.incorrect.toDouble(),
    };

    return PieChart(
      dataMap: dataMap,
      colorList: const [Colors.green, Colors.red],
      chartType: ChartType.disc,
      chartValuesOptions: const ChartValuesOptions(
        showChartValuesInPercentage: true,
        showChartValueBackground: false,
        chartValueStyle: TextStyle(color: Colors.white),
      ),
      legendOptions: const LegendOptions(
        legendTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildStreakChart() {
    if (_streakSpots.length < 2) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      height: 200,
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
                FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              spots: _streakSpots,
              color: accent,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCompletedBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _goalCompleted
          ? Container(
              key: const ValueKey('goalBadge'),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Цель выполнена',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('emptyBadge')),
    );
  }

  Widget _buildAllGoalsCompletedBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _allGoalsCompleted
          ? Container(
              key: const ValueKey('allGoalsBadge'),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Все цели выполнены',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('emptyAllGoalsBadge')),
    );
  }

  Widget _buildMistakePerDayChart() {
    if (_mistakesPerDay.isEmpty) return const SizedBox.shrink();

    final maxCount =
        _mistakesPerDay.map((e) => e.value).reduce(max);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < _mistakesPerDay.length; i++) {
      final count = _mistakesPerDay[i].value;
      const color = Colors.redAccent;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    double interval = 1;
    if (maxCount > 5) {
      interval = (maxCount / 5).ceilToDouble();
    }

    final step = (_mistakesPerDay.length / 6).ceil();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxCount.toDouble(),
          minY: 0,
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
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _mistakesPerDay.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0 && index != _mistakesPerDay.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = _mistakesPerDay[index].key;
                  final label =
                      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
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
          barGroups: groups,
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final summary = _summary;
    if (summary == null) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final completedGoals =
        context.read<GoalsService>().goals.where((g) => g.progress >= g.target).length;

    final maxStreak = _streakSpots.isEmpty
        ? 0
        : _streakSpots.map((e) => e.y).reduce(max).toInt();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text('Прогресс', style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Выполнено целей: $completedGoals',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Всего разобрано раздач: ${summary.totalHands}',
                style: pw.TextStyle(font: regularFont)),
            if (summary.totalHands > 0) ...[
              pw.SizedBox(height: 16),
              pw.Text('Результаты',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Container(
                height: 200,
                child: pw.Chart(
                  grid: pw.PieGrid(),
                  datasets: [
                    pw.PieDataSet(
                      value: summary.correct.toDouble(),
                      color: PdfColors.green,
                      legend: 'Верно',
                    ),
                    pw.PieDataSet(
                      value: summary.incorrect.toDouble(),
                      color: PdfColors.red,
                      legend: 'Ошибка',
                    ),
                  ],
                ),
              ),
            ],
            if (_streakSpots.length > 1) ...[
              pw.SizedBox(height: 16),
              pw.Text('История стрика',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Container(
                height: 200,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis(
                      [for (var i = 0; i < _streakSpots.length; i++) i],
                      divisions: true,
                      marginStart: 30,
                    ),
                    yAxis: pw.FixedAxis(
                      [for (var i = 0; i <= maxStreak; i++) i],
                      divisions: true,
                      marginStart: 30,
                    ),
                  ),
                  datasets: [
                    pw.LineDataSet(
                      drawPoints: false,
                      isCurved: false,
                      data: [
                        for (final spot in _streakSpots)
                          pw.PointChartValue(spot.x, spot.y),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'progress_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  void dispose() {
    context.read<GoalsService>().removeListener(_onGoalsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsService>();
    final completedGoals =
        goals.goals.where((g) => g.progress >= g.target).length;
    final totalHands = _summary?.totalHands ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История целей',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Drill-История',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DrillHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Достижения',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGoalCompletedBadge(),
          _buildAllGoalsCompletedBadge(),
          const Text(
            'Результаты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildPieChart(),
          const SizedBox(height: 24),
          const Text(
            'История стрика',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildStreakChart(),
          const SizedBox(height: 24),
          const Text(
            'Ошибки по дням',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMistakePerDayChart(),
          const SizedBox(height: 24),
          const Text(
            'Ошибки по позициям и улицам',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          MistakeHeatmap(data: _heatmapData),
          const SizedBox(height: 24),
          Text(
            'Выполнено целей: $completedGoals',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Всего разобрано раздач: $totalHands',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
