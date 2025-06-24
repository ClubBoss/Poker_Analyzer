import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/session_accuracy_distribution_chart.dart';
import '../widgets/common/mistake_by_street_chart.dart';
import '../widgets/common/session_volume_accuracy_chart.dart';
import 'saved_hands_screen.dart';

class SessionStatsScreen extends StatefulWidget {
  const SessionStatsScreen({super.key});

  @override
  State<SessionStatsScreen> createState() => _SessionStatsScreenState();
}

class _SessionStatsScreenState extends State<SessionStatsScreen> {
  String? _activeTag;
  final Set<int> _selectedStreets = {0, 1, 2, 3};

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

  Widget _buildStat(String label, String value, {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }

  Widget _buildTag(BuildContext context, String tag, int count) {
    final selected = _activeTag == tag;
    final accent = Theme.of(context).colorScheme.secondary;
    final style = TextStyle(
      color: selected ? accent : Colors.white,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
    );
    return InkWell(
      onTap: () => setState(() => _activeTag = selected ? null : tag),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tag, style: style),
            Text(count.toString(), style: style),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionRow(String pos, int correct, int total,
      {VoidCallback? onTap}) {
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$pos — $accuracy% точность ($correct из $total верно)',
        style: const TextStyle(color: Colors.white),
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }

  Widget _buildAccuracyProgress(
      BuildContext context, int good, int total) {
    final progress = total > 0 ? good / total : 0.0;
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Сессии с точностью > 80%',
                  style: TextStyle(color: Colors.white70)),
              Text('$good из $total',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(BuildContext context, int good) {
    final progress = (good / 10.0).clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Цель месяца: 10 сессий с точностью > 90%',
                    style: TextStyle(color: Colors.white70)),
              ),
              Text('$good из 10',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _diffColor(num diff, bool higherIsBetter) {
    final improvement = higherIsBetter ? diff > 0 : diff < 0;
    return improvement ? Colors.green : Colors.red;
  }

  String _formatAccuracyDiff(double diff) {
    final arrow = diff >= 0 ? '▲' : '▼';
    final sign = diff >= 0 ? '+' : '-';
    return '$arrow $sign${diff.abs().toStringAsFixed(1)}% accuracy vs last session';
  }

  String _formatMistakeDiff(int diff) {
    final arrow = diff <= 0 ? '▼' : '▲';
    final sign = diff > 0 ? '+' : '-';
    return '$arrow $sign${diff.abs()} mistakes vs last session';
  }

  Widget _buildStreetFilters() {
    const labels = ['Preflop', 'Flop', 'Turn', 'River'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          for (int i = 0; i < labels.length; i++)
            FilterChip(
              label: Text(labels[i]),
              selected: _selectedStreets.contains(i),
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedStreets.add(i);
                } else {
                  _selectedStreets.remove(i);
                }
              }),
            ),
        ],
      ),
    );
  }

  _StatsSummary _gatherStats(
      SavedHandManagerService manager,
      SessionNoteService notes,
      Set<int> streets) {
    final hands = (_activeTag == null
            ? manager.hands
            : manager.hands.where((h) => h.tags.contains(_activeTag)).toList())
        .where((h) => streets.contains(h.boardStreet.clamp(0, 3)))
        .toList();
    final Map<int, List<SavedHand>> grouped = {};
    for (final hand in hands) {
      grouped.putIfAbsent(hand.sessionId, () => []).add(hand);
    }

    final Map<int, _SessionData> sessionStats = {};

    int totalHands = hands.length;
    Duration totalDuration = Duration.zero;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int sessionsWithNotes = 0;
    int sessionsAbove80 = 0;
    int sessionsAbove90 = 0;
    final sessionAccuracies = <double>[];
    final sessionPoints = <SessionVolumeAccuracyPoint>[];
    final streetErrors = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};

    for (final entry in grouped.entries) {
      final id = entry.key;
      final list = List<SavedHand>.from(entry.value)
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      if (list.isEmpty) continue;
      final start = list.first.savedAt;
      final end = list.last.savedAt;
      totalDuration += end.difference(start);

      int correct = 0;
      int incorrect = 0;
      for (final h in list) {
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
      sessionStats[id] = _SessionData(correct, incorrect);
      totalCorrect += correct;
      totalIncorrect += incorrect;

      final total = correct + incorrect;
      if (total > 0 && (correct / total * 100) >= 80) {
        sessionsAbove80++;
      }
      if (total > 0 && (correct / total * 100) >= 90) {
        sessionsAbove90++;
      }
      if (total > 0) {
        final acc = correct / total * 100.0;
        sessionAccuracies.add(acc);
        sessionPoints.add(SessionVolumeAccuracyPoint(end, acc, total));
      }

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

    double? accuracyDiff;
    int? mistakeDiff;
    if (sessionStats.length > 1) {
      final ids = sessionStats.keys.toList()..sort();
      final last = sessionStats[ids.last]!;
      final prev = sessionStats[ids[ids.length - 2]]!;
      final lastAcc = last.total > 0 ? last.correct / last.total * 100 : 0;
      final prevAcc = prev.total > 0 ? prev.correct / prev.total * 100 : 0;
      accuracyDiff = lastAcc - prevAcc;
      mistakeDiff = last.incorrect - prev.incorrect;
    }

    final tagCountsAll = <String, int>{};
    for (final hand in manager.hands.where((h) => streets.contains(h.boardStreet.clamp(0, 3)))) {
      for (final tag in hand.tags) {
        tagCountsAll[tag] = (tagCountsAll[tag] ?? 0) + 1;
      }
    }
    final tagCounts = <String, int>{};
    final errorTagCounts = <String, int>{};
    final positionTotals = <String, int>{'SB': 0, 'BB': 0};
    final positionCorrect = <String, int>{'SB': 0, 'BB': 0};
    for (final hand in hands) {
      final expected = hand.expectedAction;
      final gto = hand.gtoAction;
      final isError = expected != null &&
          gto != null &&
          expected.trim().toLowerCase() != gto.trim().toLowerCase();
      for (final tag in hand.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        if (isError) {
          errorTagCounts[tag] = (errorTagCounts[tag] ?? 0) + 1;
        }
      }
      final pos = hand.heroPosition;
      if (positionTotals.containsKey(pos)) {
        positionTotals[pos] = positionTotals[pos]! + 1;
        if (!isError) {
          positionCorrect[pos] = positionCorrect[pos]! + 1;
        }
      }
      if (isError) {
        final s = hand.boardStreet.clamp(0, 3);
        streetErrors[s] = (streetErrors[s] ?? 0) + 1;
      }
    }
    final tagEntries = tagCountsAll.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final errorTagEntries = errorTagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String? mistakeTag;
    int mistakeTotal = 0;
    int mistakeErrors = 0;
    double highestRate = 0;
    for (final entry in tagCounts.entries) {
      final total = entry.value;
      if (total < 20) continue;
      final errors = errorTagCounts[entry.key] ?? 0;
      if (errors == 0) continue;
      final rate = errors / total;
      if (rate > highestRate) {
        highestRate = rate;
        mistakeTag = entry.key;
        mistakeTotal = total;
        mistakeErrors = errors;
      }
    }

    return _StatsSummary(
      totalHands: totalHands,
      sessionsCount: sessionsCount,
      avgDuration: avgDuration,
      overallAccuracy: overallAccuracy,
      sessionsWithNotes: sessionsWithNotes,
      sessionsAbove80: sessionsAbove80,
      sessionsAbove90: sessionsAbove90,
      sessionAccuracies: sessionAccuracies,
      sessions: sessionPoints,
      weekly: weekly,
      tagEntries: tagEntries,
      errorTagEntries: errorTagEntries,
      positionTotals: positionTotals,
      positionCorrect: positionCorrect,
      mistakeTag: mistakeTag,
      mistakeTotal: mistakeTotal,
      mistakeErrors: mistakeErrors,
      mistakeRate: highestRate,
      mistakesByStreet: {
        'Preflop': streetErrors[0] ?? 0,
        'Flop': streetErrors[1] ?? 0,
        'Turn': streetErrors[2] ?? 0,
        'River': streetErrors[3] ?? 0,
      },
      accuracyDiff: accuracyDiff,
      mistakeDiff: mistakeDiff,
    );
  }

  Map<String, int> _accuracyHistogram(List<double> accuracies) {
    final labels = ['50–60%', '60–70%', '70–80%', '80–90%', '90–100%'];
    final counts = <String, int>{for (final l in labels) l: 0};
    for (final a in accuracies) {
      if (a >= 50 && a < 60) {
        counts['50–60%'] = counts['50–60%']! + 1;
      } else if (a < 70) {
        counts['60–70%'] = counts['60–70%']! + 1;
      } else if (a < 80) {
        counts['70–80%'] = counts['70–80%']! + 1;
      } else if (a < 90) {
        counts['80–90%'] = counts['80–90%']! + 1;
      } else {
        counts['90–100%'] = counts['90–100%']! + 1;
      }
    }
    return counts;
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final notes = context.read<SessionNoteService>();
    final summary = _gatherStats(manager, notes, _selectedStreets);

    final buffer = StringBuffer()
      ..writeln('# Статистика сессий')
      ..writeln('- Всего раздач: ${summary.totalHands}')
      ..writeln('- Средняя длительность: ${_formatDuration(summary.avgDuration)}');
    if (summary.overallAccuracy != null) {
      buffer.writeln('- Точность: ${summary.overallAccuracy!.toStringAsFixed(1)}%');
    }
    buffer
      ..writeln('- Сессий с заметками: ${summary.sessionsWithNotes}')
      ..writeln('- Сессий с точностью > 80%: ${summary.sessionsAbove80} из ${summary.sessionsCount}')
      ..writeln('- Цель месяца: ${summary.sessionsAbove90} из 10')
      ..writeln();

    final hist = _accuracyHistogram(summary.sessionAccuracies);
    if (hist.values.any((v) => v > 0)) {
      buffer.writeln('## Распределение точности');
      for (final e in hist.entries) {
        buffer.writeln('- ${e.key}: ${e.value}');
      }
      buffer.writeln();
    }

    if (summary.mistakeTag != null) {
      buffer.writeln('## Типичная ошибка');
      buffer.writeln(
          '- ${summary.mistakeTag}: ${(summary.mistakeRate * 100).round()}% ошибок (${summary.mistakeErrors} из ${summary.mistakeTotal})');
      buffer.writeln();
    }

    if (summary.errorTagEntries.isNotEmpty) {
      buffer.writeln('## Ошибки по тегам');
      for (final e in summary.errorTagEntries) {
        buffer.writeln('- ${e.key}: ${e.value}');
      }
      buffer.writeln();
    }

    if (summary.positionTotals.values.any((v) => v > 0)) {
      buffer.writeln('## Ошибки по позициям');
      if (summary.positionTotals['SB']! > 0) {
        final acc = (summary.positionCorrect['SB']! / summary.positionTotals['SB']! * 100).round();
        buffer.writeln('- SB — $acc% (${summary.positionCorrect['SB']} из ${summary.positionTotals['SB']} верно)');
      }
      if (summary.positionTotals['BB']! > 0) {
        final acc = (summary.positionCorrect['BB']! / summary.positionTotals['BB']! * 100).round();
        buffer.writeln('- BB — $acc% (${summary.positionCorrect['BB']} из ${summary.positionTotals['BB']} верно)');
      }
      buffer.writeln();
    }

    if (summary.tagEntries.isNotEmpty) {
      buffer.writeln('## Использование тегов');
      for (final e in summary.tagEntries) {
        buffer.writeln('- ${e.key}: ${e.value}');
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_stats.md');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'session_stats.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: session_stats.md')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final notes = context.read<SessionNoteService>();
    final summary = _gatherStats(manager, notes, _selectedStreets);

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final hist = _accuracyHistogram(summary.sessionAccuracies);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text('Статистика сессий',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Всего раздач: ${summary.totalHands}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Средняя длительность: ${_formatDuration(summary.avgDuration)}',
                style: pw.TextStyle(font: regularFont)),
            if (summary.overallAccuracy != null)
              pw.Text('Точность: ${summary.overallAccuracy!.toStringAsFixed(1)}%',
                  style: pw.TextStyle(font: regularFont)),
            pw.Text('Сессий с заметками: ${summary.sessionsWithNotes}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text(
                'Сессий с точностью > 80%: ${summary.sessionsAbove80} из ${summary.sessionsCount}',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Цель месяца: ${summary.sessionsAbove90} из 10',
                style: pw.TextStyle(font: regularFont)),
            if (hist.values.any((v) => v > 0)) ...[
              pw.SizedBox(height: 12),
              pw.Text('Распределение точности',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              for (final e in hist.entries)
                pw.Text('${e.key}: ${e.value}',
                    style: pw.TextStyle(font: regularFont)),
            ],
            if (summary.mistakeTag != null) ...[
              pw.SizedBox(height: 12),
              pw.Text('Типичная ошибка',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              pw.Text(
                  '${summary.mistakeTag}: ${(summary.mistakeRate * 100).round()}% ошибок (${summary.mistakeErrors} из ${summary.mistakeTotal})',
                  style: pw.TextStyle(font: regularFont)),
            ],
            if (summary.errorTagEntries.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Ошибки по тегам',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              for (final e in summary.errorTagEntries)
                pw.Text('${e.key}: ${e.value}',
                    style: pw.TextStyle(font: regularFont)),
            ],
            if (summary.positionTotals.values.any((v) => v > 0)) ...[
              pw.SizedBox(height: 12),
              pw.Text('Ошибки по позициям',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              if (summary.positionTotals['SB']! > 0)
                pw.Text(
                    'SB — ${(summary.positionCorrect['SB']! / summary.positionTotals['SB']! * 100).round()}% точность (${summary.positionCorrect['SB']} из ${summary.positionTotals['SB']} верно)',
                    style: pw.TextStyle(font: regularFont)),
              if (summary.positionTotals['BB']! > 0)
                pw.Text(
                    'BB — ${(summary.positionCorrect['BB']! / summary.positionTotals['BB']! * 100).round()}% точность (${summary.positionCorrect['BB']} из ${summary.positionTotals['BB']} верно)',
                    style: pw.TextStyle(font: regularFont)),
            ],
            if (summary.tagEntries.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Использование тегов',
                  style: pw.TextStyle(font: boldFont, fontSize: 18)),
              for (final e in summary.tagEntries)
                pw.Text('${e.key}: ${e.value}',
                    style: pw.TextStyle(font: regularFont)),
            ],
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/session_stats.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'session_stats.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: session_stats.pdf')),
      );
    }
  }

  Future<void> _showExportOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(ctx, 'md'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'md') {
      await _exportMarkdown(context);
    } else if (result == 'pdf') {
      await _exportPdf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final notes = context.watch<SessionNoteService>();
    final summary = _gatherStats(manager, notes, _selectedStreets);

    final weekly = summary.weekly;
    final sessionSeries = summary.sessions;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Экспорт',
            onPressed: _showExportOptions,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'PDF',
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_activeTag != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => setState(() => _activeTag = null),
                child: const Text('Сбросить фильтр'),
              ),
            ),
          _buildStat('Всего раздач', summary.totalHands.toString()),
          _buildStat('Сред. длительность', _formatDuration(summary.avgDuration)),
          if (summary.overallAccuracy != null)
            _buildStat('Точность', '${summary.overallAccuracy!.toStringAsFixed(1)}%'),
          if (summary.accuracyDiff != null || summary.mistakeDiff != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.accuracyDiff != null)
                    Text(
                      _formatAccuracyDiff(summary.accuracyDiff!),
                      style: TextStyle(color: _diffColor(summary.accuracyDiff!, true)),
                    ),
                  if (summary.mistakeDiff != null)
                    Text(
                      _formatMistakeDiff(summary.mistakeDiff!),
                      style: TextStyle(color: _diffColor(summary.mistakeDiff!, false)),
                    ),
                ],
              ),
            ),
          _buildStat('Сессий с заметками', summary.sessionsWithNotes.toString()),
          _buildAccuracyProgress(context, summary.sessionsAbove80, summary.sessionsCount),
          _buildGoalProgress(context, summary.sessionsAbove90),
          _buildStreetFilters(),
          MistakeByStreetChart(counts: summary.mistakesByStreet),
          SessionAccuracyDistributionChart(accuracies: summary.sessionAccuracies),
          SessionVolumeAccuracyChart(sessions: sessionSeries),
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
          if (summary.mistakeTag != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Типичная ошибка',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.mistakeTag}: ${(summary.mistakeRate * 100).round()}% ошибок (${summary.mistakeErrors} из ${summary.mistakeTotal})',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (summary.tagEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Использование тегов',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in summary.tagEntries) _buildTag(context, e.key, e.value),
          ],
          if (summary.errorTagEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Ошибки по тегам',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (final e in summary.errorTagEntries)
              _buildStat(
                e.key,
                e.value.toString(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialTag: e.key,
                        initialAccuracy: 'Только ошибки',
                      ),
                    ),
                  );
                },
              ),
          ],
          if (summary.positionTotals.values.any((v) => v > 0)) ...[
            const SizedBox(height: 16),
            const Text('Ошибки по позициям',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            if (summary.positionTotals['SB']! > 0)
              _buildPositionRow(
                'SB',
                summary.positionCorrect['SB']!,
                summary.positionTotals['SB']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialPosition: 'SB',
                        initialAccuracy: 'Только ошибки',
                      ),
                    ),
                  );
                },
              ),
            if (summary.positionTotals['BB']! > 0)
              _buildPositionRow(
                'BB',
                summary.positionCorrect['BB']!,
                summary.positionTotals['BB']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialPosition: 'BB',
                        initialAccuracy: 'Только ошибки',
                      ),
                    ),
                  );
                },
              ),
          ],
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

class _SessionData {
  final int correct;
  final int incorrect;

  int get total => correct + incorrect;

  _SessionData(this.correct, this.incorrect);
}

class _StatsSummary {
  final int totalHands;
  final int sessionsCount;
  final Duration avgDuration;
  final double? overallAccuracy;
  final int sessionsWithNotes;
  final int sessionsAbove80;
  final int sessionsAbove90;
  final List<double> sessionAccuracies;
  final List<SessionVolumeAccuracyPoint> sessions;
  final List<_WeekData> weekly;
  final List<MapEntry<String, int>> tagEntries;
  final List<MapEntry<String, int>> errorTagEntries;
  final Map<String, int> positionTotals;
  final Map<String, int> positionCorrect;
  final String? mistakeTag;
  final int mistakeTotal;
  final int mistakeErrors;
  final double mistakeRate;
  final Map<String, int> mistakesByStreet;
  final double? accuracyDiff;
  final int? mistakeDiff;

  const _StatsSummary({
    required this.totalHands,
    required this.sessionsCount,
    required this.avgDuration,
    required this.overallAccuracy,
    required this.sessionsWithNotes,
    required this.sessionsAbove80,
    required this.sessionsAbove90,
    required this.sessionAccuracies,
    required this.sessions,
    required this.weekly,
    required this.tagEntries,
    required this.errorTagEntries,
    required this.positionTotals,
    required this.positionCorrect,
    required this.mistakeTag,
    required this.mistakeTotal,
    required this.mistakeErrors,
    required this.mistakeRate,
    required this.mistakesByStreet,
    this.accuracyDiff,
    this.mistakeDiff,
  });
}

