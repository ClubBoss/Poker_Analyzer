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

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  SummaryResult? _summary;
  List<FlSpot> _streakSpots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gatherData());
  }

  void _gatherData() {
    final manager = context.read<SavedHandManagerService>();
    final executor = EvaluationExecutorService();
    final hands = manager.hands;
    final summary = executor.summarizeHands(hands);

    final sorted = [...hands]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    int streak = 0;
    for (var i = 0; i < sorted.length; i++) {
      final h = sorted[i];
      final correct = h.expectedAction != null &&
          h.gtoAction != null &&
          h.expectedAction!.trim().toLowerCase() ==
              h.gtoAction!.trim().toLowerCase();
      streak = correct ? streak + 1 : 0;
      spots.add(FlSpot(i.toDouble(), streak.toDouble()));
    }

    setState(() {
      _summary = summary;
      _streakSpots = spots;
    });
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
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
