import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/common/accuracy_chart.dart';
import '../widgets/common/history_list_item.dart';

import '../models/training_result.dart';
import '../helpers/date_utils.dart';

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
  final List<TrainingResult> _history = [];
  int _filterDays = 7;
  _SortOption _sort = _SortOption.newest;
  _RatingFilter _ratingFilter = _RatingFilter.all;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortKey) ?? 0;
    final ratingIndex = prefs.getInt(_ratingKey) ?? 0;
    setState(() {
      _sort = _SortOption.values[sortIndex];
      _ratingFilter = _RatingFilter.values[ratingIndex];
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

  Future<void> _resetFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortKey, _SortOption.newest.index);
    await prefs.setInt(_ratingKey, _RatingFilter.all.index);
    setState(() {
      _sort = _SortOption.newest;
      _ratingFilter = _RatingFilter.all;
    });
  }

  List<TrainingResult> _getFilteredHistory() {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    final list = _history
        .where((r) => r.date.isAfter(cutoff))
        .where((r) {
          final min = switch (_ratingFilter) {
            _RatingFilter.all => 0,
            _RatingFilter.pct40 => 40,
            _RatingFilter.pct60 => 60,
            _RatingFilter.pct80 => 80,
          };
          return r.accuracy >= min;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        centerTitle: true,
        actions: [
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
                Builder(builder: (context) {
                  final filtered = _getFilteredHistory();
                  return AccuracyChart(sessions: filtered);
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
                Expanded(
                  child: Builder(builder: (context) {
                    final filtered = _getFilteredHistory();
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return HistoryListItem(result: result);
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
