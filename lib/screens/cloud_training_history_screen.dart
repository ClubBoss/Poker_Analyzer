import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/training_result.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/common/accuracy_trend_chart.dart';
import 'cloud_training_session_details_screen.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

enum _SortMode { dateDesc, dateAsc, mistakesDesc, accuracyAsc }

enum _ChartMode { daily, weekly, monthly }

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  List<CloudTrainingSession> _sessions = [];
  bool _loading = true;
  _SortMode _sort = _SortMode.dateDesc;
  _ChartMode _chartMode = _ChartMode.daily;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<CloudSyncService>();
    final sessions = await service.loadTrainingSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  void _openSession(CloudTrainingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CloudTrainingSessionDetailsScreen(session: session),
      ),
    );
  }

  Future<void> _exportMarkdown() async {
    if (_sessions.isEmpty) return;
    final buffer = StringBuffer();
    for (final s in _getSortedSessions()) {
      buffer.writeln(
          '- ${formatDateTime(s.date)}: ${s.accuracy.toStringAsFixed(1)}% — Ошибок: ${s.mistakes}');
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    try {
      await FileSaver.instance.saveAs(
        name: 'training_history',
        bytes: bytes,
        ext: 'md',
        mimeType: MimeType.other,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('История сохранена в training_history.md')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта')));
      }
    }
  }

  List<CloudTrainingSession> _getSortedSessions() {
    final list = [..._sessions];
    switch (_sort) {
      case _SortMode.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortMode.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortMode.mistakesDesc:
        list.sort((a, b) => b.mistakes.compareTo(a.mistakes));
        break;
      case _SortMode.accuracyAsc:
        list.sort((a, b) => a.accuracy.compareTo(b.accuracy));
        break;
    }
    return list;
  }

  List<TrainingResult> _groupSessionsForChart(List<CloudTrainingSession> list) {
    if (_chartMode == _ChartMode.daily) {
      final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
      return [
        for (final s in sorted)
          TrainingResult(
            date: s.date,
            total: s.total,
            correct: s.correct,
            accuracy: s.accuracy,
          )
      ];
    }

    final Map<DateTime, List<CloudTrainingSession>> groups = {};
    for (final r in list) {
      DateTime key;
      switch (_chartMode) {
        case _ChartMode.weekly:
          final d = DateTime(r.date.year, r.date.month, r.date.day);
          key = d.subtract(Duration(days: d.weekday - 1));
          break;
        case _ChartMode.monthly:
          key = DateTime(r.date.year, r.date.month);
          break;
        case _ChartMode.daily:
          key = DateTime(r.date.year, r.date.month, r.date.day);
          break;
      }
      groups.putIfAbsent(key, () => []).add(r);
    }

    final result = <TrainingResult>[];
    final keys = groups.keys.toList()..sort();
    for (final k in keys) {
      final sessions = groups[k]!;
      final total = sessions.fold<int>(0, (p, e) => p + e.total);
      final correct = sessions.fold<int>(0, (p, e) => p + e.correct);
      final accuracy = total == 0 ? 0.0 : correct * 100 / total;
      result.add(TrainingResult(
        date: k,
        total: total,
        correct: correct,
        accuracy: accuracy,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: _sessions.isEmpty ? null : _exportMarkdown,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Text('История пуста',
                      style: TextStyle(color: Colors.white70)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('Сортировка',
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 8),
                          DropdownButton<_SortMode>(
                            value: _sort,
                            dropdownColor: const Color(0xFF2A2B2E),
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: _SortMode.dateDesc,
                                child: Text('Дата (новые)'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.dateAsc,
                                child: Text('Дата (старые)'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.mistakesDesc,
                                child: Text('Ошибок (много → мало)'),
                              ),
                              DropdownMenuItem(
                                value: _SortMode.accuracyAsc,
                                child: Text('Точность (меньше → больше)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sort = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Период',
                              style: TextStyle(color: Colors.white)),
                          const Spacer(),
                          ToggleButtons(
                            isSelected: [
                              _chartMode == _ChartMode.daily,
                              _chartMode == _ChartMode.weekly,
                              _chartMode == _ChartMode.monthly,
                            ],
                            onPressed: (index) =>
                                setState(() => _chartMode = _ChartMode.values[index]),
                            borderRadius: BorderRadius.circular(4),
                            selectedColor: Colors.white,
                            fillColor: Colors.blueGrey,
                            color: Colors.white70,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('День'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Неделя'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Месяц'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final grouped =
                            _groupSessionsForChart(_getSortedSessions());
                        return AccuracyTrendChart(
                          sessions: grouped,
                          mode: ChartMode.values[_chartMode.index],
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _getSortedSessions().length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = _getSortedSessions()[index];
                          return ListTile(
                            title: Text(
                              formatDateTime(s.date),
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s.accuracy.toStringAsFixed(1)}% • Ошибок: ${s.mistakes}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (s.comment != null && s.comment!.isNotEmpty)
                                  Text(
                                    s.comment!,
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.chevron_right, color: Colors.white70),
                            onTap: () => _openSession(s),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
