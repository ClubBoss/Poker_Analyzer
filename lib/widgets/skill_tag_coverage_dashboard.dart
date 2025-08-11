import 'dart:async';

import 'package:flutter/material.dart';

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
    final stream = widget.statsStream ??
        Stream.periodic(
          const Duration(seconds: 1),
          (_) => SkillTagCoverageTrackerService.instance.getCoverageStats(),
        );
    final tagCategoryMap =
        widget.tagCategoryMap ??
            SkillTagCoverageTrackerService.instance.tagCategoryMap;
    final allTags = widget.allTags ??
        SkillTagCoverageTrackerService.instance.allSkillTags;

    return StreamBuilder<SkillTagStats>(
      stream: stream,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        _rows = _buildRows(stats, allTags, tagCategoryMap);
        _applySort();
        final categorySummary =
            computeCategorySummary(stats, allTags, tagCategoryMap);
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
                          label: const Text('Category'), onSort: _onSort),
                      DataColumn(
                          label: const Text('Packs Covered'),
                          numeric: true,
                          onSort: _onSort),
                      DataColumn(
                          label: const Text('Spots Covered'),
                          numeric: true,
                          onSort: _onSort),
                      DataColumn(
                          label: const Text('Coverage %'),
                          numeric: true,
                          onSort: _onSort),
                      DataColumn(
                          label: const Text('Last Updated'), onSort: _onSort),
                    ],
                    rows: [
                      for (final r in _filteredRows())
                        DataRow(
                          cells: [
                            DataCell(Text(r.tag),
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/trainingPacks',
                                        arguments: r.tag)),
                            DataCell(Text(r.category)),
                            DataCell(Text('${r.packs}')),
                            DataCell(Text('${r.spots}')),
                            DataCell(Text(r.coverage.toStringAsFixed(1))),
                            DataCell(Text(
                                r.lastUpdated?.toIso8601String() ?? '')),
                          ],
                          color: MaterialStateProperty.resolveWith<Color?>((_) {
                            final index =
                                r.category.hashCode % Colors.primaries.length;
                            return Colors.primaries[index].withOpacity(0.1);
                          }),
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
    final total = stats.totalTags == 0 ? 1 : stats.totalTags;
    final rows = <_TagRow>[];
    for (final tag in allTags) {
      final norm = tag.toLowerCase();
      final spots = stats.tagCounts[norm] ?? 0;
      final packs = stats.packsPerTag[norm] ?? 0;
      final coverage = spots / total * 100;
      final last = stats.tagLastUpdated[norm];
      final cat = catMap[norm] ?? 'uncategorized';
      rows.add(_TagRow(tag, cat, packs, spots, coverage, last));
    }
    return rows;
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
            cmp = a.tag.compareTo(b.tag);
            break;
          case 1:
            cmp = a.category.compareTo(b.category);
            break;
          case 2:
            cmp = a.packs.compareTo(b.packs);
            break;
          case 3:
            cmp = a.spots.compareTo(b.spots);
            break;
          case 4:
            cmp = a.coverage.compareTo(b.coverage);
            break;
          case 5:
            final at = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
            final bt = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
            cmp = at.compareTo(bt);
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
    _rows.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.tag.compareTo(b.tag);
          break;
        case 1:
          cmp = a.category.compareTo(b.category);
          break;
        case 2:
          cmp = a.packs.compareTo(b.packs);
          break;
        case 3:
          cmp = a.spots.compareTo(b.spots);
          break;
        case 4:
          cmp = a.coverage.compareTo(b.coverage);
          break;
        case 5:
          final at = a.lastUpdated?.millisecondsSinceEpoch ?? 0;
          final bt = b.lastUpdated?.millisecondsSinceEpoch ?? 0;
          cmp = at.compareTo(bt);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
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

