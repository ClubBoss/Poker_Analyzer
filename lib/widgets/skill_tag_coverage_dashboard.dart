import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/skill_tag_stats.dart';
import '../services/skill_tag_coverage_tracker_service.dart';
import '../utils/skill_tag_coverage_utils.dart';

class SkillTagCoverageDashboard extends StatefulWidget {
  final Stream<SkillTagStats>? statsStream;
  final Map<String, String>? tagCategoryMap;
  final Set<String>? allTags;

  const SkillTagCoverageDashboard({
    super.key,
    this.statsStream,
    this.tagCategoryMap,
    this.allTags,
  });

  @override
  State<SkillTagCoverageDashboard> createState() =>
      _SkillTagCoverageDashboardState();
}

class _TagRow {
  final String tag;
  final String category;
  final int packs;
  final int spots;
  final double coverage;
  final DateTime? lastUpdated;

  _TagRow(
    this.tag,
    this.category,
    this.packs,
    this.spots,
    this.coverage,
    this.lastUpdated,
  );
}

class _SkillTagCoverageDashboardState extends State<SkillTagCoverageDashboard> {
  bool _showUncoveredOnly = false;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<_TagRow> _rows = <_TagRow>[];

  @override
  Widget build(BuildContext context) {
    final stream =
        widget.statsStream ??
        Stream.periodic(const Duration(seconds: 10), (_) {
          return SkillTagCoverageTrackerService.instance.getCoverageStats();
        });
    final tagCategoryMap =
        widget.tagCategoryMap ??
        SkillTagCoverageTrackerService.instance.tagCategoryMap;
    final allTagsInput =
        widget.allTags ?? SkillTagCoverageTrackerService.instance.allSkillTags;

    return StreamBuilder<SkillTagStats>(
      stream: stream,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final allTags = allTagsInput.isEmpty
            ? stats.tagCounts.keys.toSet()
            : allTagsInput;
        _rows = _buildRows(stats, allTags, tagCategoryMap);
        _applySort();
        final categorySummary = computeCategorySummary(
          stats,
          allTags,
          tagCategoryMap,
        );
        final baseColor = Theme.of(context).colorScheme.surface;
        final df = DateFormat('yyyy-MM-dd');
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Show only uncovered'),
              value: _showUncoveredOnly,
              onChanged: (v) => setState(() => _showUncoveredOnly = v),
            ),
            _buildCategoryTable(categorySummary),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(label: const Text('Tag'), onSort: _onSort),
                      DataColumn(
                        label: const Text('Category'),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Packs Covered'),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Spots Covered'),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Occurrence %'),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text('Last Updated'),
                        onSort: _onSort,
                      ),
                    ],
                    rows: [
                      for (final r in _filteredRows())
                        DataRow(
                          cells: [
                            DataCell(
                              Text(r.tag),
                              onTap: () {
                                try {
                                  Navigator.of(context).pushNamed(
                                    '/trainingPacks',
                                    arguments: r.tag,
                                  );
                                } catch (_) {
                                  // Route может отсутствовать - молча игнорируем.
                                }
                              },
                            ),
                            DataCell(Text(r.category)),
                            DataCell(Text('${r.packs}')),
                            DataCell(Text('${r.spots}')),
                            DataCell(
                              Text(
                                r.spots == 0
                                    ? '-'
                                    : '${r.coverage.toStringAsFixed(1)}%',
                              ),
                            ),
                            DataCell(
                              Text(
                                r.lastUpdated != null
                                    ? df.format(r.lastUpdated!)
                                    : '',
                              ),
                            ),
                          ],
                          color: MaterialStatePropertyAll(
                            Color.alphaBlend(
                              Colors
                                  .primaries[r.category.hashCode %
                                      Colors.primaries.length]
                                  .withValues(alpha: 0.08),
                              baseColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_TagRow> _buildRows(
    SkillTagStats stats,
    Set<String> allTags,
    Map<String, String> catMap,
  ) {
    final totalSpots = stats.spotTags.length;
    return allTags.map((tag) {
      final norm = tag.toLowerCase();
      final spots = stats.tagCounts[norm] ?? 0;
      final packs = stats.packsPerTag[norm] ?? 0;
      final last = stats.tagLastUpdated[norm];
      final cat = catMap[norm] ?? 'uncategorized';
      final coverage = totalSpots > 0 ? (spots / totalSpots) * 100 : 0.0;
      return _TagRow(tag, cat, packs, spots, coverage, last);
    }).toList();
  }

  List<_TagRow> _filteredRows() {
    if (!_showUncoveredOnly) return _rows;
    return _rows.where((r) => r.spots == 0).toList();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _rows.sort((a, b) {
        int cmp;
        switch (columnIndex) {
          case 0:
            cmp = _cmpPrimary<String>(a.tag, b.tag);
            break;
          case 1:
            cmp = _cmpWithTie<String, String>(a.category, b.category, a.tag, b.tag);
            break;
          case 2:
            cmp = _cmpWithTie<int, String>(a.packs, b.packs, a.tag, b.tag);
            break;
          case 3:
            cmp = _cmpWithTie<int, String>(a.spots, b.spots, a.tag, b.tag);
            break;
          case 4:
            cmp = _cmpWithTie<double, String>(a.coverage, b.coverage, a.tag, b.tag);
            break;
          case 5:
            final at = a.lastUpdated?.millisecondsSinceEpoch;
            final bt = b.lastUpdated?.millisecondsSinceEpoch;
            if (at == null && bt == null) {
              cmp = _cmpWithTie<int, String>(0, 0, a.tag, b.tag);
            } else if (at == null) {
              cmp = 1;
            } else if (bt == null) {
              cmp = -1;
            } else {
              cmp = _cmpWithTie<int, String>(at, bt, a.tag, b.tag);
            }
            break;
          default:
            cmp = 0;
        }
        return ascending ? cmp : -cmp;
      });
    });
  }

  void _applySort() {
    if (_sortColumnIndex == null) return;
    _onSort(_sortColumnIndex!, _sortAscending);
  }

  // Разделил компараторы, чтобы типы для вторичного ключа могли отличаться.
  int _cmpPrimary<T extends Comparable>(T a, T b) => a.compareTo(b);

  int _cmpWithTie<T extends Comparable, U extends Comparable>(
      T a, T b, [U? a2, U? b2]) {
    final c = a.compareTo(b);
    if (c != 0 || a2 == null || b2 == null) return c;
    return a2.compareTo(b2);
  }

  Widget _buildCategoryTable(Map<String, CategorySummary> summary) {
    final rows = summary.entries
        .map(
          (e) => DataRow(
            cells: [
              DataCell(Text(e.key)),
              DataCell(Text('${e.value.total}')),
              DataCell(Text('${e.value.covered}')),
              DataCell(Text('${e.value.uncovered}')),
              DataCell(Text(e.value.avg.toStringAsFixed(1))),
            ],
          ),
        )
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Total Tags'), numeric: true),
          DataColumn(label: Text('Covered'), numeric: true),
          DataColumn(label: Text('Uncovered'), numeric: true),
          DataColumn(label: Text('Avg %'), numeric: true),
        ],
        rows: rows,
      ),
    );
  }
}
