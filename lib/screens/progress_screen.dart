import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/png_exporter.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../widgets/common/interactive_line_chart.dart';

import '../services/goals_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_storage_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/training_stats_service.dart';
import '../models/summary_result.dart';
import '../models/saved_hand.dart';
import '../theme/app_colors.dart';
import '../helpers/poker_street_helper.dart';
import '../widgets/mistake_heatmap.dart';
import '../widgets/eval_stats_card.dart';
import '../widgets/ev_icm_history_chart.dart';
import 'goals_history_screen.dart';
import 'daily_spot_screen.dart';
import 'daily_spot_history_screen.dart';
import 'daily_spot_history_calendar_screen.dart';
import 'achievements_screen.dart';
import 'drill_history_screen.dart';
import 'goal_drill_screen.dart';
import 'weekly_progress_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';
import '../widgets/xp_progress_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  SummaryResult? _summary;
  List<FlSpot> _streakSpots = [];
  List<MapEntry<DateTime, int>> _mistakesPerDay = [];
  List<MapEntry<DateTime, double>> _weeklyAccuracy = [];
  List<MapEntry<DateTime, double>> _dailyEvLoss = [];
  Map<String, Map<String, int>> _heatmapData = {};
  bool _goalCompleted = false;
  bool _allGoalsCompleted = false;
  bool _dailySpotDone = false;
  int _dailyWeekCount = 0;
  int _dailyMonthCount = 0;
  bool _weeklyStreak = false;
  late final ConfettiController _weeklyConfetti;
  final _pieKey = GlobalKey();
  final _weeklyAccKey = GlobalKey();
  final _evLossKey = GlobalKey();
  final _evIcmKey = GlobalKey();
  final _streakKey = GlobalKey();
  final _mistakeKey = GlobalKey();
  final _heatmapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _weeklyConfetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _gatherData());
    final goals = context.read<GoalsService>();
    _goalCompleted = goals.anyCompleted;
    _allGoalsCompleted = goals.goals.every((g) => g.completed);
    _loadDailySpot();
    _loadDailySpotStats();
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
    final weekMap = <DateTime, List<SavedHand>>{};
    final heatmap = {
      for (final p in ['BB', 'SB', 'BTN', 'CO', 'MP', 'UTG'])
        p: {for (final s in kStreetNames) s: 0},
    };
    for (var i = 0; i < sorted.length; i++) {
      final h = sorted[i];
      final correct =
          h.expectedAction.trim().toLowerCase() ==
          h.gtoAction.trim().toLowerCase();
      streak = correct ? streak + 1 : 0;
      if (!correct) {
        final day = DateTime(h.date.year, h.date.month, h.date.day);
        counts.update(day, (v) => v + 1, ifAbsent: () => 1);
        final pos = h.heroPosition;
        final street = streetName(h.boardStreet);
        if (heatmap.containsKey(pos)) {
          heatmap[pos]![street] = heatmap[pos]![street]! + 1;
        }
      }
      final d = DateTime(h.date.year, h.date.month, h.date.day);
      weekMap.putIfAbsent(d, () => []).add(h);
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = entries.where((e) => e.key.isAfter(cutoff)).toList();

    final start = DateTime.now().subtract(const Duration(days: 6));
    final weekStart = DateTime(start.year, start.month, start.day);
    final stats = context.read<TrainingStatsService>();
    final evLossMap = {
      for (final e in stats.getDailyEvLossData(hands)) e.key: e.value,
    };
    final evLoss = <MapEntry<DateTime, double>>[];
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      evLoss.add(MapEntry(d, -(evLossMap[d] ?? 0)));
    }
    final weekAcc = <MapEntry<DateTime, double>>[];
    final days = weekMap.keys.where((d) => !d.isBefore(weekStart)).toList()
      ..sort();
    for (final day in days) {
      final list = weekMap[day]!;
      int c = 0;
      int t = 0;
      for (final h in list) {
        final exp = h.expectedAction;
        final gto = h.gtoAction;
        if (exp != null && gto != null) {
          t++;
          if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) {
            c++;
          }
        }
      }
      if (t > 0) {
        weekAcc.add(MapEntry(day, c / t * 100));
      }
    }

    final xpHistory = context
        .read<XPTrackerService>()
        .history
        .reversed
        .toList();
    spots
      ..clear()
      ..addAll([
        for (var i = 0; i < xpHistory.length; i++)
          FlSpot(i.toDouble(), xpHistory[i].streak.toDouble()),
      ]);

    setState(() {
      _summary = summary;
      _streakSpots = spots;
      _mistakesPerDay = recent;
      _heatmapData = heatmap;
      _weeklyAccuracy = weekAcc;
      _dailyEvLoss = evLoss;
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

  Future<void> _loadDailySpot() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('daily_spot_date');
    if (dateStr == null) return;
    final date = DateTime.tryParse(dateStr);
    final now = DateTime.now();
    if (date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      setState(() => _dailySpotDone = true);
    }
  }

  Future<void> _loadDailySpotStats() async {
    final service = context.read<GoalsService>();
    final history = await service.getDailySpotHistory();
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6));
    final monthStart = now.subtract(const Duration(days: 29));
    int week = 0;
    int month = 0;
    for (final d in history) {
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(weekStart)) week++;
      if (!day.isBefore(monthStart)) month++;
    }
    setState(() {
      _dailyWeekCount = week;
      _dailyMonthCount = month;
    });
    final streak = await service.hasWeeklyStreak();
    if (streak && !service.hasSevenDayGoalUnlocked) {
      await service.setSevenDayGoalUnlocked(true);
    }
    if (streak && !service.weeklyStreakCelebrated) {
      _weeklyConfetti.play();
      service.markWeeklyStreakCelebrated();
    }
    if (mounted) {
      setState(() => _weeklyStreak = streak);
    }
  }

  Widget _buildPieChart() {
    final summary = _summary;
    if (summary == null || summary.totalHands == 0) {
      return const SizedBox.shrink();
    }

    final total = summary.totalHands.toDouble();
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        sections: [
          PieChartSectionData(
            value: summary.correct.toDouble(),
            color: Colors.green,
            title: '${(summary.correct * 100 / total).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(color: Colors.white),
          ),
          PieChartSectionData(
            value: summary.incorrect.toDouble(),
            color: Colors.red,
            title: '${(summary.incorrect * 100 / total).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakChart() {
    if (_streakSpots.length < 2) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InteractiveLineChart(
        data: LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
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
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
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
              spots: _streakSpots,
              color: accent,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAccuracyChart() {
    if (_weeklyAccuracy.isEmpty) {
      return Container(
        height: responsiveSize(context, 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Недостаточно данных',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    final accent = Theme.of(context).colorScheme.secondary;
    final spots = <FlSpot>[];
    for (var i = 0; i < _weeklyAccuracy.length; i++) {
      spots.add(FlSpot(i.toDouble(), _weeklyAccuracy[i].value));
    }
    final step = (_weeklyAccuracy.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InteractiveLineChart(
        data: LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
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
                interval: 20,
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
                  if (index < 0 || index >= _weeklyAccuracy.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0 &&
                      index != _weeklyAccuracy.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = _weeklyAccuracy[index].key;
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: accent,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvLossChart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _dailyEvLoss.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyEvLoss[i].value));
    }
    final minY = _dailyEvLoss.map((e) => e.value).reduce(min);
    final interval = minY.abs() < 1 ? 1.0 : (minY.abs() / 5).ceilToDouble();
    final step = (_dailyEvLoss.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InteractiveLineChart(
        data: LineChartData(
          minY: minY,
          maxY: 0,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((s) {
                  final entry = _dailyEvLoss[s.spotIndex];
                  final date = DateFormat(
                    'd MMM',
                    Intl.getCurrentLocale(),
                  ).format(entry.key);
                  return LineTooltipItem(
                    '$date: ${entry.value.toStringAsFixed(1)} bb',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
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
                  final index = value.toInt();
                  if (index < 0 || index >= _dailyEvLoss.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0 && index != _dailyEvLoss.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = _dailyEvLoss[index].key;
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: Colors.redAccent,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: Colors.redAccent,
                      strokeWidth: 0,
                    ),
              ),
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

    final maxCount = _mistakesPerDay.map((e) => e.value).reduce(max);
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
                colors: [color.withValues(alpha: 0.7), color],
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
      height: responsiveSize(context, 200),
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
                  if (index % step != 0 &&
                      index != _mistakesPerDay.length - 1) {
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

    final completedGoals = context
        .read<GoalsService>()
        .goals
        .where((g) => g.progress >= g.target)
        .length;

    final maxStreak = _streakSpots.isEmpty
        ? 0
        : _streakSpots.map((e) => e.y).reduce(max).toInt();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text(
              'Прогресс',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Выполнено целей: $completedGoals',
              style: pw.TextStyle(font: regularFont),
            ),
            pw.Text(
              'Всего разобрано раздач: ${summary.totalHands}',
              style: pw.TextStyle(font: regularFont),
            ),
            if (summary.totalHands > 0) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Результаты',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.Container(
                height: responsiveSize(context, 200),
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
              pw.Text(
                'История стрика',
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
              pw.Container(
                height: responsiveSize(context, 200),
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

  Future<Uint8List?> _capture(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return PngExporter.captureBoundary(boundary);
  }

  Future<void> _exportChartsPdf() async {
    final list = <Uint8List>[];
    final keys = [
      _pieKey,
      _weeklyAccKey,
      _evLossKey,
      _evIcmKey,
      _streakKey,
      _mistakeKey,
      _heatmapKey,
    ];
    for (final k in keys) {
      final img = await _capture(k);
      if (img != null) list.add(img);
    }
    if (list.isEmpty) return;
    final bytes = await PngExporter.imagesToPdf(list);
    final dir = await getTemporaryDirectory();
    var path = '${dir.path}/progress.pdf';
    if (await File(path).exists()) {
      path =
          '${dir.path}/progress_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved: $path')));
  }

  @override
  void dispose() {
    context.read<GoalsService>().removeListener(_onGoalsChanged);
    _weeklyConfetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsService>();
    final completedGoals = goals.goals
        .where((g) => g.progress >= g.target)
        .length;
    final totalHands = _summary?.totalHands ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
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
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Charts PDF',
            onPressed: _exportChartsPdf,
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
          const XPProgressCard(),
          _buildGoalCompletedBadge(),
          _buildAllGoalsCompletedBadge(),
          isPortrait(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalDrillScreen(),
                          ),
                        );
                      },
                      child: const Text('Отработать цель'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DrillHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text('История тренировок'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WeeklyProgressScreen(),
                          ),
                        );
                      },
                      child: const Text('Прогресс 7д'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalDrillScreen(),
                          ),
                        );
                      },
                      child: const Text('Отработать цель'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DrillHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text('История тренировок'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WeeklyProgressScreen(),
                          ),
                        );
                      },
                      child: const Text('Прогресс 7д'),
                    ),
                  ],
                ),
          const Text(
            'Результаты',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(key: _pieKey, child: _buildPieChart()),
          const SizedBox(height: 12),
          const EvalStatsCard(),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _dailySpotDone
                ? null
                : () async {
                    final service = context.read<GoalsService>();
                    final packs = context
                        .read<TrainingPackStorageService>()
                        .packs;
                    final hand = await service.getDailySpot(packs);
                    if (hand == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailySpotScreen(hand: hand),
                      ),
                    );
                    _loadDailySpot();
                    _loadDailySpotStats();
                  },
            child: Text(_dailySpotDone ? '✅ Выполнено' : 'Спот дня'),
          ),
          const SizedBox(height: 24),
          const Text(
            '🔥 Точность за неделю',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _weeklyAccKey,
            child: _buildWeeklyAccuracyChart(),
          ),
          const SizedBox(height: 24),
          const Text(
            '💸 Потеря EV за неделю',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(key: _evLossKey, child: _buildEvLossChart()),
          const SizedBox(height: 24),
          const Text(
            'EV/ICM история',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(key: _evIcmKey, child: const EvIcmHistoryChart()),
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
          RepaintBoundary(key: _streakKey, child: _buildStreakChart()),
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
          RepaintBoundary(key: _mistakeKey, child: _buildMistakePerDayChart()),
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
          RepaintBoundary(
            key: _heatmapKey,
            child: MistakeHeatmap(data: _heatmapData),
          ),
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
          const SizedBox(height: 24),
          const Text(
            '📅 Статистика спотов дня',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dailyWeekCount > 0
                ? 'За неделю: $_dailyWeekCount / 7 дней'
                : 'Нет активности за период',
            style: TextStyle(
              color: _dailyWeekCount > 0 ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dailyMonthCount > 0
                ? 'За месяц: $_dailyMonthCount / 30 дней'
                : 'Нет активности за период',
            style: TextStyle(
              color: _dailyMonthCount > 0 ? Colors.white : Colors.white70,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailySpotHistoryScreen(),
                ),
              );
            },
            child: const Text('История'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailySpotHistoryCalendarScreen(),
                ),
              );
            },
            child: const Text('Календарь'),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _weeklyStreak
                ? Stack(
                    key: const ValueKey('weeklyStreak'),
                    alignment: Alignment.center,
                    children: [
                      Card(
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            '🔥 Серия 7 дней!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ConfettiWidget(
                          confettiController: _weeklyConfetti,
                          numberOfParticles: 20,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('noWeeklyStreak')),
          ),
        ],
      ),
    );
  }
}
