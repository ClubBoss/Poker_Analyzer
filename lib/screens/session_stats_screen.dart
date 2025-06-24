import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../theme/app_colors.dart';

class SessionStatsScreen extends StatelessWidget {
  const SessionStatsScreen({super.key});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (h > 0) parts.add('${h}ч');
    parts.add('${m}м');
    return parts.join(' ');
  }

  List<_WeekData> _weeklyWinrates(Map<int, List<SavedHand>> data) {
    final Map<DateTime, List<double>> grouped = {};
    for (final entry in data.entries) {
      final hands = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (hands.isEmpty) continue;
      final end = hands.last.savedAt;
      int correct = 0;
      int incorrect = 0;
      for (final h in hands) {
        final expected = h.expectedAction;
        final gto = h.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            correct++;
          } else {
            incorrect++;
          }
        }
      }
      final total = correct + incorrect;
      if (total == 0) continue;
      final winrate = correct / total * 100.0;
      final weekStart = DateTime(end.year, end.month, end.day - (end.weekday - 1));
      grouped.putIfAbsent(weekStart, () => []).add(winrate);
    }
    final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries)
        _WeekData(
          e.key,
          e.value.reduce((a, b) => a + b) / e.value.length,
        )
    ];
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final notes = context.watch<SessionNoteService>();
    final grouped = manager.handsBySession();

    int totalHands = manager.hands.length;
    Duration totalDuration = Duration.zero;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int sessionsWithNotes = 0;

    for (final entry in grouped.entries) {
      final id = entry.key;
      final hands = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (hands.isEmpty) continue;
      final start = hands.first.savedAt;
      final end = hands.last.savedAt;
      totalDuration += end.difference(start);

      int correct = 0;
      int incorrect = 0;
      for (final h in hands) {
        final expected = h.expectedAction;
        final gto = h.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            correct++;
          } else {
            incorrect++;
          }
        }
      }
      totalCorrect += correct;
      totalIncorrect += incorrect;

      final note = notes.noteFor(id);
      if (note.trim().isNotEmpty) sessionsWithNotes++;
    }

    final sessionsCount = grouped.length;
    final avgDuration = sessionsCount > 0
        ? Duration(minutes: (totalDuration.inMinutes / sessionsCount).round())
        : Duration.zero;
    final overallAccuracy = totalCorrect + totalIncorrect > 0
        ? (totalCorrect / (totalCorrect + totalIncorrect) * 100)
        : null;

    final weekly = _weeklyWinrates(grouped);
    final spots = <FlSpot>[];
    for (var i = 0; i < weekly.length; i++) {
      spots.add(FlSpot(i.toDouble(), weekly[i].winrate));
    }
    final step = (weekly.length / 6).ceil();

    final line = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.greenAccent,
      barWidth: 2,
      dotData: FlDotData(show: false),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика сессий'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStat('Всего раздач', totalHands.toString()),
          _buildStat('Сред. длительность', _formatDuration(avgDuration)),
          if (overallAccuracy != null)
            _buildStat('Точность', '${overallAccuracy.toStringAsFixed(1)}%'),
          _buildStat('Сессий с заметками', sessionsWithNotes.toString()),
          const SizedBox(height: 16),
          if (weekly.length > 1)
            Container(
              height: 200,
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
                        FlLine(color: Colors.white24, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          if (index < 0 || index >= weekly.length) {
                            return const SizedBox.shrink();
                          }
                          if (index % step != 0 && index != weekly.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final d = weekly[index].weekStart;
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
                  lineBarsData: [line],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekData {
  final DateTime weekStart;
  final double winrate;

  _WeekData(this.weekStart, this.winrate);
}

