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
import '../widgets/common/history_list_item.dart';
import '../widgets/common/session_accuracy_bar_chart.dart';
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

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  static const _sortKey = 'training_history_sort';
  static const _ratingKey = 'training_history_rating';
  static const _tagKey = 'training_history_tags';
  static const _showChartsKey = 'training_history_show_charts';
  static const _dateFromKey = 'training_history_date_from';
  static const _dateToKey = 'training_history_date_to';

  final List<TrainingResult> _history = [];
  int _filterDays = 7;
  _SortOption _sort = _SortOption.newest;
  _RatingFilter _ratingFilter = _RatingFilter.all;
  Set<String> _selectedTags = {};
  bool _showCharts = true;

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
    final fromMillis = prefs.getInt(_dateFromKey);
    final toMillis = prefs.getInt(_dateToKey);
    setState(() {
      _sort = _SortOption.values[sortIndex];
      _ratingFilter = _RatingFilter.values[ratingIndex];
      _selectedTags = tags.toSet();
      _showCharts = showCharts ?? true;
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
    if (_history.isEmpty) return;
    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Total', 'Correct', 'Accuracy', 'Tags']);
    for (final r in _history) {
      rows.add([
        formatDateTime(r.date),
        r.total,
        r.correct,
        r.accuracy.toStringAsFixed(1),
        r.tags.join(';'),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.csv');
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

  List<TrainingResult> _getFilteredHistory() {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
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
          if (_selectedTags.isEmpty) return true;
          return r.tags.any(_selectedTags.contains);
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

  Future<void> _toggleCharts() async {
    setState(() => _showCharts = !_showCharts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showChartsKey, _showCharts);
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _toggleCharts,
                  child: Text(
                    _showCharts ? 'Скрыть графики' : 'Показать графики',
                  ),
                ),
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
                if (_selectedTags.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final tag in _selectedTags)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(tag),
                              selected: true,
                              onSelected: (selected) async {
                                final prefs =
                                    await SharedPreferences.getInstance();
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
                  ),
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
                      onPressed: _history.isEmpty ? null : _exportCsv,
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
