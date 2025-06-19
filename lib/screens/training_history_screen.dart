import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../theme/app_colors.dart';
import '../widgets/common/accuracy_chart.dart';
import '../widgets/common/average_accuracy_chart.dart';
import '../widgets/common/history_list_item.dart';
import '../widgets/common/session_accuracy_bar_chart.dart';
import '../widgets/common/accuracy_distribution_chart.dart';
import 'training_detail_screen.dart';

import '../models/training_result.dart';
import '../helpers/date_utils.dart';
import '../helpers/accuracy_utils.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

enum _SortOption { newest, oldest, rating }

enum _RatingFilter { all, pct40, pct60, pct80 }

enum _ChartMode { daily, weekly, monthly }

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  static const _sortKey = 'training_history_sort';
  static const _ratingKey = 'training_history_rating';
  static const _tagKey = 'training_history_tags';
  static const _showChartsKey = 'training_history_show_charts';
  static const _showAvgChartKey = 'training_history_show_chart';
  static const _showDistributionKey = 'training_history_show_distribution';
  static const _dateFromKey = 'training_history_date_from';
  static const _dateToKey = 'training_history_date_to';
  static const _chartModeKey = 'training_history_chart_mode';
  static const _hideEmptyTagsKey = 'hide_empty_tags';

  final List<TrainingResult> _history = [];
  int _filterDays = 7;
  _SortOption _sort = _SortOption.newest;
  _RatingFilter _ratingFilter = _RatingFilter.all;
  Set<String> _selectedTags = {};
  bool _showCharts = true;
  bool _showAvgChart = true;
  bool _showDistribution = true;
  bool _hideEmptyTags = false;
  _ChartMode _chartMode = _ChartMode.daily;

  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortKey) ?? 0;
    final ratingIndex = prefs.getInt(_ratingKey) ?? 0;
    final tags = prefs.getStringList(_tagKey) ?? [];
    final showCharts = prefs.getBool(_showChartsKey);
    final showAvgChart = prefs.getBool(_showAvgChartKey);
    final showDistribution = prefs.getBool(_showDistributionKey);
    final hideEmptyTags = prefs.getBool(_hideEmptyTagsKey) ?? false;
    final chartModeIndex = prefs.getInt(_chartModeKey) ?? 0;
    final fromMillis = prefs.getInt(_dateFromKey);
    final toMillis = prefs.getInt(_dateToKey);
    setState(() {
      _sort = _SortOption.values[sortIndex];
      _ratingFilter = _RatingFilter.values[ratingIndex];
      _selectedTags = tags.toSet();
      _showCharts = showCharts ?? true;
      _showAvgChart = showAvgChart ?? true;
      _showDistribution = showDistribution ?? true;
      _hideEmptyTags = hideEmptyTags;
      _chartMode = _ChartMode.values[chartModeIndex];
      _dateFrom =
          fromMillis != null ? DateTime.fromMillisecondsSinceEpoch(fromMillis) : null;
      _dateTo =
          toMillis != null ? DateTime.fromMillisecondsSinceEpoch(toMillis) : null;
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('training_history') ?? [];
    final List<TrainingResult> loaded = [];
    for (final item in stored) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          loaded.add(TrainingResult.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (_) {}
    }
    setState(() {
      _history
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_history');
    setState(() {
      _history.clear();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final r in _history) jsonEncode(r.toJson())];
    await prefs.setStringList('training_history', list);
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) return;
    final encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final r in _history) r.toJson()]);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.json');
  }

  Future<void> _exportCsv() async {
    final sessions = _getFilteredHistory();
    if (sessions.isEmpty) return;
    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Total', 'Correct', 'Accuracy', 'Tags']);
    for (final r in sessions) {
      rows.add([
        formatDateTime(r.date),
        r.total,
        r.correct,
        r.accuracy.toStringAsFixed(1),
        r.tags.join(';'),
      ]);
    }
    final csvStr = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.csv');
  }

  Future<void> _exportChartCsv() async {
    final filtered = _getFilteredHistory();
    final grouped = _groupSessionsForChart(filtered);
    if (grouped.isEmpty) return;

    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Total', 'Correct', 'Accuracy']);
    for (final r in grouped) {
      rows.add([
        formatDate(r.date),
        r.total,
        r.correct,
        r.accuracy.toStringAsFixed(1),
      ]);
    }

    final csvStr = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();

    String mode;
    switch (_chartMode) {
      case _ChartMode.daily:
        mode = 'daily';
        break;
      case _ChartMode.weekly:
        mode = 'weekly';
        break;
      case _ChartMode.monthly:
        mode = 'monthly';
        break;
    }

    final fileName = 'chart_${mode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
    }
  }

  Future<void> _importHistory() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file format')),
        );
        return;
      }
      final List<TrainingResult> imported = [];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            imported.add(
                TrainingResult.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      if (imported.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sessions found')),
        );
        return;
      }
      final existingDates =
          _history.map((e) => e.date.toIso8601String()).toSet();
      final newSessions = [
        for (final r in imported)
          if (!existingDates.contains(r.date.toIso8601String())) r
      ];
      if (newSessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to import')),
        );
        return;
      }
      setState(() => _history.addAll(newSessions));
      await _saveHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${newSessions.length} sessions')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to read file')),
      );
    }
  }

  Future<void> _resetFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortKey, _SortOption.newest.index);
    await prefs.setInt(_ratingKey, _RatingFilter.all.index);
    await prefs.remove(_tagKey);
    await prefs.remove(_dateFromKey);
    await prefs.remove(_dateToKey);
    setState(() {
      _sort = _SortOption.newest;
      _ratingFilter = _RatingFilter.all;
      _selectedTags.clear();
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Future<void> _clearTagFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tagKey);
    setState(() => _selectedTags.clear());
  }

  Future<void> _clearDateFilter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateFromKey);
    await prefs.remove(_dateToKey);
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
  }

  List<TrainingResult> _getFilteredHistory({Set<String>? tags}) {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    final selected = tags ?? _selectedTags;
    final list = _history
        .where((r) => r.date.isAfter(cutoff))
        .where((r) => _dateFrom == null || !r.date.isBefore(_dateFrom!))
        .where((r) => _dateTo == null || !r.date.isAfter(_dateTo!))
        .where((r) {
          final min = switch (_ratingFilter) {
            _RatingFilter.all => 0,
            _RatingFilter.pct40 => 40,
            _RatingFilter.pct60 => 60,
            _RatingFilter.pct80 => 80,
          };
          return r.accuracy >= min;
        })
        .where((r) {
          if (selected.isEmpty) return true;
          return r.tags.any(selected.contains);
        })
        .toList();
    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortOption.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortOption.rating:
        list.sort((a, b) => b.accuracy.compareTo(a.accuracy));
        break;
    }
    return list;
  }

  double _calculateAverageAccuracy(List<TrainingResult> list) {
    if (list.isEmpty) return 0.0;
    final sum = list.map((e) => e.accuracy).reduce((a, b) => a + b);
    return sum / list.length;
  }

  List<TrainingResult> _groupSessionsForChart(List<TrainingResult> list) {
    if (_chartMode == _ChartMode.daily) {
      final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
      return sorted;
    }

    final Map<DateTime, List<TrainingResult>> groups = {};
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
      result.add(TrainingResult(date: k, total: total, correct: correct, accuracy: accuracy));
    }
    return result;
  }

  bool _hasResultsForTag(String tag) {
    return _getFilteredHistory(tags: {tag}).isNotEmpty;
  }

  Future<void> _showTagSelector() async {
    final tags = {for (final r in _history) ...r.tags};
    final local = Set<String>.from(_selectedTags);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Фильтр по тегам',
              style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in tags)
                      CheckboxListTile(
                        value: local.contains(tag),
                        title: Text(tag,
                            style: const TextStyle(color: Colors.white)),
                        onChanged: (checked) {
                          setStateDialog(() {
                            if (checked ?? false) {
                              local.add(tag);
                            } else {
                              local.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_tagKey, result.toList());
      setState(() => _selectedTags = result);
    }
  }

  Future<void> _editSessionTags(BuildContext ctx, TrainingResult session) async {
    final tags = {for (final r in _history) ...r.tags};
    final local = Set<String>.from(session.tags);
    final updated = await showDialog<Set<String>>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Теги сессии',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in tags)
                      CheckboxListTile(
                        value: local.contains(tag),
                        title: Text(tag,
                            style: const TextStyle(color: Colors.white)),
                        onChanged: (checked) {
                          setStateDialog(() {
                            if (checked ?? false) {
                              local.add(tag);
                            } else {
                              local.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (updated != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        setState(() {
          _history[index] = TrainingResult(
            date: session.date,
            total: session.total,
            correct: session.correct,
            accuracy: session.accuracy,
            tags: updated.toList(),
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _editSessionAccuracy(
      BuildContext ctx, TrainingResult session) async {
    final correctController =
        TextEditingController(text: session.correct.toString());
    final totalController =
        TextEditingController(text: session.total.toString());
    List<int>? updated = await showDialog<List<int>>(
      context: ctx,
      builder: (context) {
        int? correct = session.correct;
        int? total = session.total;
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Edit Accuracy',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: correctController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Correct'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      setStateDialog(() => correct = int.tryParse(v));
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      setStateDialog(() => total = int.tryParse(v));
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: correct != null && total != null && total! > 0
                  ? () => Navigator.pop(context, [correct!, total!])
                  : null,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (updated != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        final correct = updated[0];
        final total = updated[1];
        final newAccuracy = calculateAccuracy(correct, total);
        setState(() {
          _history[index] = TrainingResult(
            date: session.date,
            total: total,
            correct: correct,
            accuracy: newAccuracy,
            tags: session.tags,
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _deleteSession(TrainingResult session) async {
    setState(() {
      _history.remove(session);
    });
    await _saveHistory();
  }

  Future<void> _setChartsVisible(bool value) async {
    setState(() => _showCharts = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showChartsKey, _showCharts);
  }

  Future<void> _setAvgChartVisible(bool value) async {
    setState(() => _showAvgChart = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAvgChartKey, _showAvgChart);
  }

  Future<void> _setDistributionVisible(bool value) async {
    setState(() => _showDistribution = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDistributionKey, _showDistribution);
  }

  Future<void> _setHideEmptyTags(bool value) async {
    setState(() => _hideEmptyTags = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideEmptyTagsKey, _hideEmptyTags);
  }

  Future<void> _setChartMode(_ChartMode mode) async {
    setState(() => _chartMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chartModeKey, mode.index);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dateFromKey, DateUtils.dateOnly(range.start).millisecondsSinceEpoch);
      await prefs.setInt(_dateToKey, DateUtils.dateOnly(range.end).millisecondsSinceEpoch);
      setState(() {
        _dateFrom = DateUtils.dateOnly(range.start);
        _dateTo = DateUtils.dateOnly(range.end);
      });
    }
  }

  String _dateRangeLabel() {
    if (_dateFrom == null && _dateTo == null) return '';
    final fromStr = _dateFrom != null ? formatDate(_dateFrom!) : '...';
    final toStr = _dateTo != null ? formatDate(_dateTo!) : '...';
    return '$fromStr - $toStr';
  }

  Future<void> _applyQuickDateFilter(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateUtils.dateOnly(DateTime.now());
    final from = DateUtils.dateOnly(now.subtract(Duration(days: days - 1)));
    await prefs.setInt(_dateFromKey, from.millisecondsSinceEpoch);
    await prefs.setInt(_dateToKey, now.millisecondsSinceEpoch);
    setState(() {
      _dateFrom = from;
      _dateTo = now;
    });
    _loadHistory();
  }

  void _openSessionDetail(TrainingResult session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingDetailScreen(
          result: session,
          onDelete: () async {
            await _deleteSession(session);
          },
          onEditTags: (ctx) async {
            await _editSessionTags(ctx, session);
          },
          onEditAccuracy: (ctx) async {
            await _editSessionAccuracy(ctx, session);
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _importHistory,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _history.isEmpty ? null : _exportHistory,
          ),
          TextButton(
            onPressed: _clearHistory,
            child: const Text('Clear History'),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _history.isEmpty
          ? const Center(
              child: Text(
                'No history available.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Show:', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _filterDays,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(value: 90, child: Text('90 days')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterDays = value;
                            });
                          }
                        },
                      ),
                      const Spacer(),
                  Builder(builder: (context) {
                    final filtered = _getFilteredHistory();
                    final avg = _calculateAverageAccuracy(filtered);
                    return Text(
                      'Average Accuracy: ${avg.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    );
                  })
                ],
              ),
            ),
            if (_showCharts)
              Builder(builder: (context) {
                final filtered = _getFilteredHistory();
                final last7days = _history
                    .where((r) =>
                        r.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
                    .toList();
                return Column(
                  children: [
                    AccuracyChart(sessions: filtered),
                    SessionAccuracyBarChart(sessions: last7days),
                  ],
                );
              }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Скрыть пустые теги',
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: _hideEmptyTags,
                    onChanged: _setHideEmptyTags,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Фильтр по тегам',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showTagSelector,
                        child: Text(
                            _selectedTags.isEmpty ? 'Выбрать теги' : 'Изменить'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _selectedTags.isEmpty ? null : _clearTagFilters,
                        child: const Text('Сбросить теги'),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  final visibleTags = _hideEmptyTags
                      ? [
                          for (final t in _selectedTags)
                            if (_hasResultsForTag(t)) t
                        ]
                      : _selectedTags.toList();
                  return visibleTags.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 40,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final tag in visibleTags)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: FilterChip(
                                    label: Text(tag),
                                    selected: true,
                                    onSelected: (selected) async {
                                      final prefs = await SharedPreferences
                                          .getInstance();
                                      setState(() {
                                        _selectedTags.remove(tag);
                                      });
                                      await prefs.setStringList(
                                          _tagKey, _selectedTags.toList());
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                }),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Фильтр по рейтингу',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<_RatingFilter>(
                        value: _ratingFilter,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: _RatingFilter.all, child: Text('Все')),
                          DropdownMenuItem(
                              value: _RatingFilter.pct40, child: Text('40%+')),
                          DropdownMenuItem(
                              value: _RatingFilter.pct60, child: Text('60%+')),
                          DropdownMenuItem(
                              value: _RatingFilter.pct80, child: Text('80%+')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setInt(_ratingKey, value.index);
                          setState(() => _ratingFilter = value);
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text('Сортировка',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<_SortOption>(
                        value: _sort,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: _SortOption.newest,
                              child: Text('Сначала новые')),
                          DropdownMenuItem(
                              value: _SortOption.oldest,
                              child: Text('Сначала старые')),
                          DropdownMenuItem(
                              value: _SortOption.rating,
                              child: Text('По рейтингу')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setInt(_sortKey, value.index);
                          setState(() => _sort = value);
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Сбросить фильтры'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed:
                          _getFilteredHistory().isEmpty ? null : _exportCsv,
                      child: const Text('Экспорт в CSV'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickDateRange,
                        child: const Text('Фильтр по дате'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _dateFrom == null && _dateTo == null
                            ? null
                            : _clearDateFilter,
                        child: const Text('Сбросить дату'),
                      ),
                      const SizedBox(width: 8),
                      if (_dateFrom != null || _dateTo != null)
                        Text(
                          _dateRangeLabel(),
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ToggleButtons(
                    isSelected: [
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 6)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 29)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 89)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom == null && _dateTo == null,
                    ],
                    onPressed: (index) async {
                      switch (index) {
                        case 0:
                          await _applyQuickDateFilter(7);
                          break;
                        case 1:
                          await _applyQuickDateFilter(30);
                          break;
                        case 2:
                          await _applyQuickDateFilter(90);
                          break;
                        case 3:
                          await _clearDateFilter();
                          _loadHistory();
                          break;
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    selectedColor: Colors.white,
                    fillColor: Colors.blueGrey,
                    color: Colors.white70,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('7 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('30 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('90 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Все'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Builder(
                    builder: (context) {
                      final filtered = _getFilteredHistory();
                      final totalSessions = filtered.length;
                      final totalCorrect =
                          filtered.fold<int>(0, (sum, r) => sum + r.correct);
                      final avg = _calculateAverageAccuracy(filtered);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Сессии: $totalSessions',
                                style: const TextStyle(color: Colors.white)),
                            Text('Верно: $totalCorrect',
                                style: const TextStyle(color: Colors.white)),
                            Text('Средняя: ${avg.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Показать графики',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      Switch(
                        value: _showCharts,
                        onChanged: _setChartsVisible,
                      ),
                    ],
                  ),
                ),
                if (_showCharts)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Тип графика',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        ToggleButtons(
                          isSelected: [
                            _chartMode == _ChartMode.daily,
                            _chartMode == _ChartMode.weekly,
                            _chartMode == _ChartMode.monthly,
                          ],
                          onPressed: (index) =>
                              _setChartMode(_ChartMode.values[index]),
                          borderRadius: BorderRadius.circular(4),
                          selectedColor: Colors.white,
                          fillColor: Colors.blueGrey,
                          color: Colors.white70,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Дневной'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Недельный'),
                            ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Месячный'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_showCharts)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _exportChartCsv,
                      child: const Text('Экспортировать график CSV'),
                    ),
                  ),
                ),
              if (_showCharts) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                      children: [
                        const Text('Показать график',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Switch(
                          value: _showAvgChart,
                          onChanged: _setAvgChartVisible,
                        ),
                      ],
                    ),
                  ),
                  if (_showAvgChart) ...[
                  Builder(
                    builder: (context) {
                      final filtered = _getFilteredHistory();
                      final grouped = _groupSessionsForChart(filtered);
                      return AverageAccuracyChart(sessions: grouped);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Показать распределение',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Switch(
                          value: _showDistribution,
                          onChanged: _setDistributionVisible,
                        ),
                      ],
                    ),
                  ),
                  if (_showDistribution)
                    Builder(
                      builder: (context) {
                        final filtered = _getFilteredHistory();
                        final grouped = _groupSessionsForChart(filtered);
                        return AccuracyDistributionChart(sessions: grouped);
                      },
                    ),
                ],
                ],
                Expanded(
                  child: Builder(builder: (context) {
                    final filtered = _getFilteredHistory();
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return Dismissible(
                          key: ValueKey(result.date.toIso8601String()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
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
                                    );
                                  },
                                ) ??
                                false;
                          },
                          onDismissed: (_) => _deleteSession(result),
                          child: HistoryListItem(
                            result: result,
                            onLongPress: () => _editSessionTags(context, result),
                            onTap: () => _openSessionDetail(result),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filtered.length,
                    );
                  }),
                ),
              ],
            ),
    );
  }
}
