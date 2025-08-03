import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/date_utils.dart';
import '../models/cloud_training_session.dart';
import '../models/training_result.dart';
import '../services/cloud_training_history_service.dart';
import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_pack_screen.dart';
import '../widgets/history/accuracy_trend_chart.dart';
import 'cloud_training_session_details_screen.dart';
import '../widgets/sync_status_widget.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

enum _SortMode { dateDesc, dateAsc, mistakesDesc, accuracyAsc }

enum _ChartMode { daily, weekly, monthly }

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  static const _tagKey = 'cloud_history_tag';
  List<CloudTrainingSession> _sessions = [];
  bool _loading = true;
  _SortMode _sort = _SortMode.dateDesc;
  _ChartMode _chartMode = _ChartMode.daily;
  String _tagFilter = 'All';
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _tagFilter = prefs.getString(_tagKey) ?? 'All');
  }

  Future<void> _load() async {
    final service = context.read<CloudTrainingHistoryService>();
    final list = await service.loadSessions();
    setState(() {
      _sessions = list;
      _loading = false;
    });
    _updateTags();
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

  Future<void> _saveTagFilter() async {
    final prefs = await SharedPreferences.getInstance();
    if (_tagFilter == 'All') {
      await prefs.remove(_tagKey);
    } else {
      await prefs.setString(_tagKey, _tagFilter);
    }
  }

  void _updateTags() {
    final set = <String>{};
    for (final s in _sessions) {
      for (final list in s.handTags?.values ?? []) {
        set.addAll(list);
      }
    }
    var changed = false;
    final tags = set.toList()..sort();
    if (_tagFilter != 'All' && !tags.contains(_tagFilter)) {
      _tagFilter = 'All';
      changed = true;
    }
    setState(() => _tags = tags);
    if (changed) _saveTagFilter();
  }

  List<CloudTrainingSession> _getVisibleSessions() {
    final list = _getSortedSessions();
    if (_tagFilter == 'All') return list;
    return [
      for (final s in list)
        if (s.handTags?.values.any((v) => v.contains(_tagFilter)) ?? false) s
    ];
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

  Future<void> _drillTag() async {
    final manager = context.read<SavedHandManagerService>();
    final Map<String, SavedHand> map = {for (final h in manager.hands) h.name: h};
    final Set<String> names = {};
    for (final s in _getVisibleSessions()) {
      for (final r in s.results) {
        if (s.handTags?[r.name]?.contains(_tagFilter) ?? false) {
          names.add(r.name);
        }
      }
    }
    final hands = [for (final n in names) if (map[n] != null) map[n]!];
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Раздачи не найдены')));
      }
      return;
    }
    final pack = TrainingPack(
      name: 'Tag Drill — $_tagFilter',
      description: '',
      gameType: 'Cash Game',
      tags: const [],
      hands: hands,
      spots: const [],
      difficulty: 1,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(pack: pack, hands: hands),
      ),
    );
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
        actions: [SyncStatusIcon.of(context), 
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт',
            onPressed: _sessions.isEmpty ? null : _exportMarkdown,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      floatingActionButton: _tagFilter == 'All'
          ? null
          : FloatingActionButton.extended(
              onPressed: _drillTag,
              label: const Text('Drill Tag'),
              icon: const Icon(Icons.fitness_center),
            ),
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
                    if (_tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Тег',
                                style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _tagFilter,
                              dropdownColor: const Color(0xFF2A2B2E),
                              style: const TextStyle(color: Colors.white),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _tagFilter = v);
                                _saveTagFilter();
                              },
                              items: [
                                const DropdownMenuItem(
                                  value: 'All',
                                  child: Text('Все'),
                                ),
                                ..._tags
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ))
                                    .toList(),
                              ],
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
                            _groupSessionsForChart(_getVisibleSessions());
                        return AccuracyTrendChart(
                          sessions: grouped,
                          mode: ChartMode.values[_chartMode.index],
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _getVisibleSessions().length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = _getVisibleSessions()[index];
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
                            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                            onTap: () => _openSession(s),
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Session?'),
                                  content: const Text('Are you sure you want to delete this session?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await context.read<CloudTrainingHistoryService>().deleteSession(s.path);
                                if (mounted) {
                                  setState(() => _sessions.removeAt(index));
                                  _updateTags();
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
