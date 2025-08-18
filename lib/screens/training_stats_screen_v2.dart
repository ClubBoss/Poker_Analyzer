import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import '../services/training_stats_export_service.dart';
import '../services/file_saver_service.dart';

import '../models/training_stats_v2.dart';
import '../models/v2/hero_position.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_loader_service.dart';

enum StatsRange { today, week, month, all }

class TrainingStatsScreenV2 extends StatefulWidget {
  const TrainingStatsScreenV2({super.key});

  @override
  State<TrainingStatsScreenV2> createState() => _TrainingStatsScreenV2State();
}

class _TrainingStatsScreenV2State extends State<TrainingStatsScreenV2> {
  StatsRange _range = StatsRange.all;
  HeroPosition? _position;
  int? _stack;
  String? _tag;
  TrainingStatsV2Model? _stats;
  bool _loading = true;
  List<int> _allStacks = [];
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTimeRange? _rangeToDates() {
    final now = DateTime.now();
    switch (_range) {
      case StatsRange.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case StatsRange.week:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: now);
      case StatsRange.month:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: now);
      case StatsRange.all:
        return null;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logService = context.read<SessionLogService>();
    await logService.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    _allStacks = {for (final t in library) t.bb}.toList()..sort();
    _allTags = {
      for (final t in library)
        for (final tag in t.tags) tag.toLowerCase(),
    }.toList()..sort();
    final stats = TrainingStatsV2Model.compute(
      logs: logService.logs,
      library: library,
      range: _rangeToDates(),
      position: _position,
      stack: _stack,
      tag: _tag,
    );
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Color _tagColor(double v) {
    return Color.lerp(Colors.red, Colors.green, v) ?? Colors.green;
  }

  Widget _buildTagHeatmap(TrainingStatsV2Model stats) {
    if (stats.accuracyByTag.isEmpty) return const SizedBox();
    final maxVal = stats.accuracyByTag.values.reduce(math.max);
    final items = stats.accuracyByTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final e in items)
          Container(
            padding: const EdgeInsets.all(4),
            color: _tagColor(maxVal == 0 ? 0 : e.value / maxVal),
            child: Text(
              '${e.key} ${(e.value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildStackChart(TrainingStatsV2Model stats) {
    if (stats.accuracyByStack.isEmpty) return const SizedBox(height: 160);
    final stacks = stats.accuracyByStack.keys.toList()..sort();
    final groups = <BarChartGroupData>[];
    double maxY = 0;
    for (var i = 0; i < stacks.length; i++) {
      final s = stacks[i];
      final acc = stats.accuracyByStack[s]! * 100;
      if (acc > maxY) maxY = acc;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: acc,
              width: 8,
              borderRadius: BorderRadius.circular(2),
              color: Colors.blueAccent,
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY,
          minY: 0,
          barGroups: groups,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= stacks.length) return const SizedBox();
                  return Text(
                    '${stacks[idx]}bb',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildPositionPie(TrainingStatsV2Model stats) {
    if (stats.handsByPosition.isEmpty) return const SizedBox(height: 160);
    final entries = stats.handsByPosition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = stats.totalHands;
    final sections = <PieChartSectionData>[];
    for (final e in entries) {
      final pct = total > 0 ? e.value * 100 / total : 0;
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          title: '${e.key.label} ${pct.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: PieChart(PieChartData(sectionsSpace: 2, sections: sections)),
    );
  }

  Future<void> _showExportOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share CSV'),
              onTap: () => Navigator.pop(ctx, 'share_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share PDF'),
              onTap: () => Navigator.pop(ctx, 'share_pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save CSV'),
              onTap: () => Navigator.pop(ctx, 'save_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save PDF'),
              onTap: () => Navigator.pop(ctx, 'save_pdf'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final logs = context.read<SessionLogService>().logs;
    final library = PackLibraryLoaderService.instance.library;
    final range = _rangeToDates();
    const exporter = TrainingStatsExportService();
    if (result == 'share_csv') {
      final file = await exporter.exportCsv(
        logs: logs,
        library: library,
        range: range,
        position: _position,
        stack: _stack,
        tag: _tag,
      );
      await Share.shareXFiles([XFile(file.path)]);
    } else if (result == 'share_pdf') {
      final file = await exporter.exportPdf(
        logs: logs,
        library: library,
        range: range,
        position: _position,
        stack: _stack,
        tag: _tag,
      );
      await Share.shareXFiles([XFile(file.path)]);
    } else if (result == 'save_csv') {
      final file = await exporter.exportCsv(
        logs: logs,
        library: library,
        range: range,
        position: _position,
        stack: _stack,
        tag: _tag,
      );
      final data = await file.readAsString();
      await FileSaverService.instance.saveCsv('training_stats', data);
    } else if (result == 'save_pdf') {
      final file = await exporter.exportPdf(
        logs: logs,
        library: library,
        range: range,
        position: _position,
        stack: _stack,
        tag: _tag,
      );
      final bytes = await file.readAsBytes();
      await FileSaverService.instance.savePdf('training_stats', bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: _loading || stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    DropdownButton<StatsRange>(
                      value: _range,
                      dropdownColor: Colors.grey[900],
                      items: const [
                        DropdownMenuItem(
                          value: StatsRange.today,
                          child: Text('Today'),
                        ),
                        DropdownMenuItem(
                          value: StatsRange.week,
                          child: Text('7d'),
                        ),
                        DropdownMenuItem(
                          value: StatsRange.month,
                          child: Text('30d'),
                        ),
                        DropdownMenuItem(
                          value: StatsRange.all,
                          child: Text('All'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _range = v);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<HeroPosition?>(
                      value: _position,
                      hint: const Text(
                        'Pos',
                        style: TextStyle(color: Colors.white70),
                      ),
                      dropdownColor: Colors.grey[900],
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final p in kPositionOrder)
                          DropdownMenuItem(value: p, child: Text(p.label)),
                      ],
                      onChanged: (v) {
                        setState(() => _position = v);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int?>(
                      value: _stack,
                      hint: const Text(
                        'Stack',
                        style: TextStyle(color: Colors.white70),
                      ),
                      dropdownColor: Colors.grey[900],
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final s in _allStacks)
                          DropdownMenuItem(value: s, child: Text('${s}bb')),
                      ],
                      onChanged: (v) {
                        setState(() => _stack = v);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: _tag,
                      hint: const Text(
                        'Tag',
                        style: TextStyle(color: Colors.white70),
                      ),
                      dropdownColor: Colors.grey[900],
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final t in _allTags)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) {
                        setState(() => _tag = v);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total hands: ${stats.totalHands}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Accuracy: ${(stats.accuracy * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accuracy by Tag',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTagHeatmap(stats),
                const SizedBox(height: 16),
                const Text(
                  'Accuracy by Stack',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStackChart(stats),
                const SizedBox(height: 16),
                const Text(
                  'Hands by Position',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPositionPie(stats),
              ],
            ),
    );
  }
}
