import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/theory_tag_summary_service.dart';
import '../models/theory_tag_stats.dart';
import '../theme/app_colors.dart';

class TheoryCoverageDashboard extends StatefulWidget {
  const TheoryCoverageDashboard({super.key});

  @override
  State<TheoryCoverageDashboard> createState() =>
      _TheoryCoverageDashboardState();
}

class _TheoryCoverageDashboardState extends State<TheoryCoverageDashboard> {
  bool _loading = true;
  final List<TheoryTagStats> _data = [];
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 1;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final map = await TheoryTagSummaryService().computeSummary();
    final list = map.values.toList();
    _sort(list);
    setState(() {
      _data
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  void _sort(List<TheoryTagStats> list) {
    int compareInt(int a, int b) => a.compareTo(b);
    int compareDouble(double a, double b) => a.compareTo(b);
    switch (_sortColumnIndex) {
      case 1:
        list.sort(
          (a, b) => _ascending
              ? compareInt(a.lessonCount, b.lessonCount)
              : compareInt(b.lessonCount, a.lessonCount),
        );
        break;
      case 2:
        list.sort(
          (a, b) => _ascending
              ? compareDouble(a.avgLength, b.avgLength)
              : compareDouble(b.avgLength, a.avgLength),
        );
        break;
      case 3:
        list.sort(
          (a, b) => _ascending
              ? compareInt(a.exampleCount, b.exampleCount)
              : compareInt(b.exampleCount, a.exampleCount),
        );
        break;
      case 4:
        list.sort(
          (a, b) => _ascending
              ? (a.connectedToPath ? 1 : 0).compareTo(b.connectedToPath ? 1 : 0)
              : (b.connectedToPath ? 1 : 0).compareTo(
                  a.connectedToPath ? 1 : 0,
                ),
        );
        break;
      default:
        list.sort((a, b) => a.tag.compareTo(b.tag));
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _ascending = ascending;
      _sort(_data);
    });
  }

  List<TheoryTagStats> get _filtered {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _data;
    return [
      for (final s in _data)
        if (s.tag.toLowerCase().contains(query)) s,
    ];
  }

  DataTable _table() {
    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _ascending,
      columns: [
        DataColumn(label: const Text('Tag'), onSort: (i, a) => _onSort(i, a)),
        DataColumn(
          label: const Text('Lessons'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(
          label: const Text('Avg Len'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(
          label: const Text('Examples'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(label: const Text('Path'), onSort: (i, a) => _onSort(i, a)),
      ],
      rows: [
        for (final s in _filtered)
          DataRow(
            cells: [
              DataCell(Text(s.tag)),
              DataCell(Text('${s.lessonCount}')),
              DataCell(Text(s.avgLength.toStringAsFixed(1))),
              DataCell(Text('${s.exampleCount}')),
              DataCell(
                Icon(
                  s.connectedToPath ? Icons.check : Icons.close,
                  color: s.connectedToPath ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theory Coverage'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Search tag'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _table(),
                ),
              ],
            ),
    );
  }
}
