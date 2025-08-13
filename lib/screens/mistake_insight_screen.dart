import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/smart_review_service.dart';
import '../services/template_storage_service.dart';
import '../helpers/hand_utils.dart';
import '../models/v2/training_pack_spot.dart';
import '../theme/app_colors.dart';
import 'mistake_review_screen.dart';

class MistakeInsightScreen extends StatefulWidget {
  const MistakeInsightScreen({super.key});

  @override
  State<MistakeInsightScreen> createState() => _MistakeInsightScreenState();
}

class _MistakeInsightScreenState extends State<MistakeInsightScreen> {
  final List<String> _periods = ['7 дней', '30 дней', 'Все время'];
  String _period = 'Все время';
  bool _loading = true;
  List<TrainingPackSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = context.read<TemplateStorageService>();
    final spots = await SmartReviewService.instance
        .getMistakeSpots(templates, context: context);
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _loading = false;
    });
  }

  List<TrainingPackSpot> get _filtered {
    if (_period == 'Все время') return _spots;
    final days = _period == '7 дней' ? 7 : 30;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return [
      for (final s in _spots)
        if (!s.createdAt.isBefore(cutoff)) s
    ];
  }

  Map<String, int> _tagCounts(List<TrainingPackSpot> spots) {
    final map = <String, int>{};
    for (final s in spots) {
      for (final t in s.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        map.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  Map<String, int> _handCounts(List<TrainingPackSpot> spots) {
    final map = <String, int>{};
    for (final s in spots) {
      final code = handCode(s.hand.heroCards) ?? '';
      if (code.isEmpty) continue;
      map.update(code, (v) => v + 1, ifAbsent: () => 1);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  Widget _tagChart(Map<String, int> data) {
    final names = data.keys.take(5).toList();
    if (names.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Нет данных', style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    final maxVal = data[names.first]!.toDouble();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < names.length; i++) {
      final v = data[names[i]]!.toDouble();
      final color = AppColors.accent;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: v,
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
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxVal,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= names.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(names[i],
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxVal / 4,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
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

  Widget _handChart(Map<String, int> data) {
    final entries = data.entries.take(5).toList();
    if (entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Нет данных', style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    final sections = <PieChartSectionData>[];
    for (final e in entries) {
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          title: e.key,
          radius: 80,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(sections: sections),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = _filtered;
    final tags = _tagCounts(spots);
    final hands = _handCounts(spots);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика ошибок'),
        actions: [
          DropdownButton<String>(
            value: _period,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF2A2B2E),
            onChanged: (v) => setState(() => _period = v!),
            items: [
              for (final p in _periods)
                DropdownMenuItem(value: p, child: Text(p))
            ],
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tagChart(tags),
                const SizedBox(height: 16),
                _handChart(hands),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MistakeReviewScreen()),
                    );
                  },
                  child: const Text('Начать повторение'),
                ),
              ],
            ),
    );
  }
}
