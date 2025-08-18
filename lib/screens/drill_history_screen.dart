import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/drill_history_service.dart';
import '../theme/app_colors.dart';
import '../helpers/date_utils.dart';
import '../models/drill_result.dart';
import '../services/training_pack_storage_service.dart';
import '../models/saved_hand.dart';
import '../utils/responsive.dart';
import '../models/v2/training_pack_spot.dart';
import '../helpers/pack_spot_utils.dart';
import 'package:collection/collection.dart';
import 'training_screen.dart';

class DrillHistoryScreen extends StatefulWidget {
  const DrillHistoryScreen({super.key});

  @override
  State<DrillHistoryScreen> createState() => _DrillHistoryScreenState();
}

class _DrillHistoryScreenState extends State<DrillHistoryScreen> {
  final TextEditingController _search = TextEditingController();
  String _period = 'Все';

  List<DrillResult> _applyFilters(List<DrillResult> all) {
    final query = _search.text.toLowerCase();
    Duration? d;
    if (_period == '7 дней') {
      d = const Duration(days: 7);
    } else if (_period == '30 дней') {
      d = const Duration(days: 30);
    }
    final now = DateTime.now();
    return [
      for (final r in all)
        if ((d == null || r.date.isAfter(now.subtract(d))) &&
            (query.isEmpty || r.templateName.toLowerCase().contains(query)))
          r,
    ];
  }

  Widget _progressChart(List<DrillResult> data) {
    if (data.length < 2) {
      return SizedBox(
        height: responsiveSize(context, 200),
        child: const Center(
          child: Text(
            'Недостаточно данных',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final pct = r.total == 0 ? 0.0 : r.correct * 100 / r.total;
      spots.add(FlSpot(i.toDouble(), pct));
    }
    final step = (sorted.length / 6).ceil();
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
                  if (index < 0 || index >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0 && index != sorted.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = sorted[index].date;
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
              isCurved: true,
              color: AppColors.accent,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  void _showChart() {
    final all = context.read<DrillHistoryService>().results;
    final data = (_period == 'Все' && _search.text.trim().isEmpty)
        ? all
        : _applyFilters(all);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Прогресс'),
        content: _progressChart(data),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _repeatMistakes() async {
    final history = context.read<DrillHistoryService>().results;
    final ids = <String>{};
    for (final r in history) {
      ids.addAll(r.wrongSpotIds.where((e) => e.isNotEmpty));
    }
    if (ids.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибок не найдено')));
      return;
    }
    final packs = context.read<TrainingPackStorageService>().packs;
    final hands = <SavedHand>[];
    for (final p in packs) {
      for (final h in p.hands) {
        if (ids.contains(h.spotId)) hands.add(h);
      }
    }
    if (hands.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибок не найдено')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen.drill(
          hands: hands,
          templateName: 'Mistakes',
          anteBb: 0,
        ),
      ),
    );
  }

  Future<void> _repeatLast() async {
    final history = context.read<DrillHistoryService>().results;
    if (history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('История пуста')));
      return;
    }
    final last = history.first;
    final packs = context.read<TrainingPackStorageService>().packs;
    final pack = packs.firstWhereOrNull((p) => p.id == last.templateId);
    if (pack == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Шаблон не найден')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen.drill(
          hands: pack.hands.isNotEmpty
              ? pack.hands
              : [
                  for (final s in pack.spots)
                    handFromPackSpot(
                      s as TrainingPackSpot,
                      anteBb: pack.anteBb,
                    ),
                ],
          templateId: pack.id,
          templateName: pack.name,
          anteBb: pack.anteBb,
        ),
      ),
    );
  }

  Widget _empty() => const Center(
    child: Text('История пока пуста', style: TextStyle(color: Colors.white70)),
  );

  Widget _noResults() => const Center(
    child: Text('Нет результатов', style: TextStyle(color: Colors.white70)),
  );

  Widget _list(List<DrillResult> data) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: data.length,
    itemBuilder: (context, index) {
      final r = data[index];
      final pct = r.total == 0 ? 0 : (r.correct / r.total * 100).round();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: const Icon(Icons.history, color: Colors.white),
          title: Text(
            r.templateName,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${formatDate(r.date)} •  ${r.correct}/${r.total}  ($pct%)',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            r.evLoss.toStringAsFixed(2),
            style: TextStyle(color: r.evLoss > 0 ? Colors.red : Colors.green),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(r.templateName),
                content: Text(
                  '${formatDate(r.date)}\n'
                  'Верно: ${r.correct}/${r.total} ($pct%)\n'
                  'Потеря EV: ${r.evLoss.toStringAsFixed(2)} bb',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = context.watch<DrillHistoryService>().results;
    final filtered = _applyFilters(results);
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _showChart,
            icon: const Text('📈', style: TextStyle(fontSize: 20)),
            label: const Text('Показать график'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          IconButton(
            onPressed: _repeatMistakes,
            icon: const Text('🔁', style: TextStyle(fontSize: 20)),
            tooltip: 'Повтор ошибок',
          ),
          IconButton(
            onPressed: _repeatLast,
            icon: const Text('🔂', style: TextStyle(fontSize: 20)),
            tooltip: 'Повтор последней',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? _empty()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButton<String>(
                      value: _period,
                      underline: const SizedBox(),
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: Colors.white),
                      items: const ['Все', '7 дней', '30 дней']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _period = v ?? 'Все'),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty ? _noResults() : _list(filtered),
                ),
              ],
            ),
    );
  }
}
