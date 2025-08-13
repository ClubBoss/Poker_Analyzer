import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class TrainingProgressChartScreen extends StatefulWidget {
  static const route = '/training/progress_chart';
  const TrainingProgressChartScreen({super.key});

  @override
  State<TrainingProgressChartScreen> createState() =>
      _TrainingProgressChartScreenState();
}

class _TrainingProgressChartScreenState
    extends State<TrainingProgressChartScreen> {
  late Future<List<_DailyStats>> _statsFuture;
  bool _showTagAccuracy = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<List<_DailyStats>> _loadStats() async {
    const boxName = 'pack_review_stats_box';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.initFlutter();
      await Hive.openBox(boxName);
    }
    final box = Hive.box(boxName);
    final Map<String, _DailyStats> map = {};
    for (final dynamic value in box.values) {
      if (value is Map) {
        try {
          final date = DateTime.parse(value['date'] as String);
          final key = DateFormat('yyyy-MM-dd').format(date);
          final stat = map.putIfAbsent(key, () => _DailyStats(date));
          final correct = (value['correctHands'] ?? 0) as int;
          final total = (value['totalHands'] ?? 0) as int;
          stat.correct += correct;
          stat.total += total;
          final tagMap = Map<String, dynamic>.from(value['tagBreakdown'] ?? {});
          for (final entry in tagMap.entries) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            final tagStat =
                stat.tagStats.putIfAbsent(entry.key, () => _TagStats());
            tagStat.correct += (data['correct'] ?? 0) as int;
            tagStat.total += (data['total'] ?? 0) as int;
          }
        } catch (_) {
          // ignore malformed entries
        }
      }
    }
    final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Progress'),
        actions: [
          Row(
            children: [
              const Text('Tags'),
              Switch(
                value: _showTagAccuracy,
                onChanged: (v) => setState(() => _showTagAccuracy = v),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<_DailyStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('No data'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AccuracyChart(data: data),
              const SizedBox(height: 16),
              _HandsChart(data: data),
              if (_showTagAccuracy) ...[
                const SizedBox(height: 16),
                _TagAccuracyChart(data: data),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AccuracyChart extends StatelessWidget {
  const _AccuracyChart({required this.data});

  final List<_DailyStats> data;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].accuracy * 100));
    }
    final labels = _dateLabels(data);
    return _ChartCard(
      title: 'Accuracy (%)',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, _) => Text(v.toInt().toString()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length)
                    return const SizedBox.shrink();
                  return Text(labels[i], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(
            show: true,
            horizontalInterval: 25,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandsChart extends StatelessWidget {
  const _HandsChart({required this.data});

  final List<_DailyStats> data;

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    var maxY = 0.0;
    for (var i = 0; i < data.length; i++) {
      final total = data[i].total.toDouble();
      maxY = total > maxY ? total : maxY;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: total)],
      ));
    }
    final labels = _dateLabels(data);
    return _ChartCard(
      title: 'Hands per day',
      child: BarChart(
        BarChartData(
          maxY: maxY + 5,
          barGroups: groups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (maxY / 4).ceilToDouble(),
                getTitlesWidget: (v, _) => Text(v.toInt().toString()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length)
                    return const SizedBox.shrink();
                  return Text(labels[i], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}

class _TagAccuracyChart extends StatelessWidget {
  const _TagAccuracyChart({required this.data});

  final List<_DailyStats> data;

  @override
  Widget build(BuildContext context) {
    final tags = <String>{};
    for (final d in data) {
      tags.addAll(d.tagStats.keys);
    }
    final colors = Colors.primaries;
    var colorIndex = 0;
    final lines = <LineChartBarData>[];
    for (final tag in tags) {
      final spots = <FlSpot>[];
      for (var i = 0; i < data.length; i++) {
        final stat = data[i].tagStats[tag];
        final acc = stat == null || stat.total == 0
            ? 0.0
            : stat.correct / stat.total * 100;
        spots.add(FlSpot(i.toDouble(), acc));
      }
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 2,
        color: colors[colorIndex % colors.length],
        dotData: const FlDotData(show: false),
      ));
      colorIndex++;
    }
    final labels = _dateLabels(data);
    return _ChartCard(
      title: 'Accuracy by tag (%)',
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, _) => Text(v.toInt().toString()),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length)
                    return const SizedBox.shrink();
                  return Text(labels[i], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(
            show: true,
            horizontalInterval: 25,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: lines,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

List<String> _dateLabels(List<_DailyStats> data) {
  final df = DateFormat('MMM d');
  return data.map((e) => df.format(e.date)).toList();
}

class _DailyStats {
  _DailyStats(this.date);

  final DateTime date;
  int correct = 0;
  int total = 0;
  final Map<String, _TagStats> tagStats = {};

  double get accuracy => total == 0 ? 0 : correct / total;
}

class _TagStats {
  int correct = 0;
  int total = 0;
}
