import 'package:flutter/material.dart';

import '../models/theory_lesson_engagement_stats.dart';
import '../services/theory_engagement_analytics_service.dart';

/// Displays aggregated engagement stats for theory mini-lessons in a
/// sortable data table.
class TheoryEngagementDashboardWidget extends StatefulWidget {
  const TheoryEngagementDashboardWidget({super.key});

  @override
  State<TheoryEngagementDashboardWidget> createState() =>
      _TheoryEngagementDashboardWidgetState();
}

class _TheoryEngagementDashboardWidgetState
    extends State<TheoryEngagementDashboardWidget> {
  bool _loading = true;
  final List<TheoryLessonEngagementStats> _stats = [];
  int _sortColumnIndex = 1;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await TheoryEngagementAnalyticsService().getAllStats();
    _sort(data);
    setState(() {
      _stats
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  void _sort(List<TheoryLessonEngagementStats> list) {
    int compareInt(int a, int b) => a.compareTo(b);
    int compareDouble(double a, double b) => a.compareTo(b);
    switch (_sortColumnIndex) {
      case 1:
        list.sort(
          (a, b) => _ascending
              ? compareInt(a.manualOpens, b.manualOpens)
              : compareInt(b.manualOpens, a.manualOpens),
        );
        break;
      case 2:
        list.sort(
          (a, b) => _ascending
              ? compareInt(a.reviewViews, b.reviewViews)
              : compareInt(b.reviewViews, a.reviewViews),
        );
        break;
      case 3:
        list.sort(
          (a, b) => _ascending
              ? compareDouble(a.successRate, b.successRate)
              : compareDouble(b.successRate, a.successRate),
        );
        break;
      default:
        list.sort((a, b) => a.lessonId.compareTo(b.lessonId));
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _ascending = ascending;
      _sort(_stats);
    });
  }

  DataTable _table() {
    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _ascending,
      columns: [
        DataColumn(
          label: const Text('Lesson'),
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(
          label: const Text('Opens'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(
          label: const Text('Views'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
        DataColumn(
          label: const Text('Success %'),
          numeric: true,
          onSort: (i, a) => _onSort(i, a),
        ),
      ],
      rows: [
        for (final s in _stats)
          DataRow(
            cells: [
              DataCell(Text(s.lessonId)),
              DataCell(Text('${s.manualOpens}')),
              DataCell(Text('${s.reviewViews}')),
              DataCell(
                Text(
                  '${(s.successRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: s.successRate < 0.3 ? Colors.red : null,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _table(),
      ),
    );
  }
}
