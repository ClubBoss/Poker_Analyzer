import 'package:flutter/material.dart';

import '../services/theory_recall_failure_hotspot_detector_service.dart';

/// Displays the top recall failure hotspots detected by
/// [TheoryRecallFailureHotspotDetectorService].
///
/// The panel can toggle between weak tags and individual spotIds.  Results are
/// shown in a sortable table with a quick navigation button to view example
/// spottings for each hotspot.
class RecallHotspotOverlayPanel extends StatefulWidget {
  /// Maximum number of hotspots to display.
  final int limit;
  const RecallHotspotOverlayPanel({super.key, this.limit = 10});

  @override
  State<RecallHotspotOverlayPanel> createState() =>
      _RecallHotspotOverlayPanelState();
}

/// Modes for hotspot analysis.
enum RecallHotspotMode { tag, spot }

class _RecallHotspotOverlayPanelState extends State<RecallHotspotOverlayPanel> {
  RecallHotspotMode _mode = RecallHotspotMode.tag;
  late Future<List<RecallHotspotEntry>> _future;
  int? _sortColumnIndex;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RecallHotspotEntry>> _load() {
    return TheoryRecallFailureHotspotDetectorService.instance
        .generateHotspotReport(mode: _mode, limit: widget.limit);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _sort<T>(
    Comparable<T> Function(RecallHotspotEntry e) getField,
    int columnIndex,
    bool ascending,
    List<RecallHotspotEntry> data,
  ) {
    data.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleButtons(
          isSelected: [
            _mode == RecallHotspotMode.tag,
            _mode == RecallHotspotMode.spot,
          ],
          onPressed: (index) {
            setState(() {
              _mode =
                  index == 0 ? RecallHotspotMode.tag : RecallHotspotMode.spot;
              _refresh();
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tags'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('SpotIds'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<RecallHotspotEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hotspots found'));
              }
              final data = snapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columns: [
                    DataColumn(
                      label: const Text('Tag/SpotId'),
                      onSort: (i, asc) => _sort((e) => e.id, i, asc, data),
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Failures'),
                      onSort: (i, asc) =>
                          _sort((e) => e.failures, i, asc, data),
                    ),
                    DataColumn(
                      label: const Text('DecayStage'),
                      onSort: (i, asc) =>
                          _sort((e) => e.decayStage, i, asc, data),
                    ),
                    DataColumn(
                      label: const Text('LastFailed'),
                      onSort: (i, asc) =>
                          _sort((e) => e.lastFailed, i, asc, data),
                    ),
                    const DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final e in data)
                      DataRow(
                        cells: [
                          DataCell(Text(e.id)),
                          DataCell(Text(e.failures.toString())),
                          DataCell(Text(e.decayStage)),
                          DataCell(Text(_formatDate(e.lastFailed))),
                          DataCell(
                            TextButton(
                              onPressed: () => _viewExamples(e),
                              child: const Text('View Examples'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _viewExamples(RecallHotspotEntry entry) {
    Navigator.of(context).pushNamed(
      '/recallHotspotExamples',
      arguments: {'mode': _mode.name, 'id': entry.id},
    );
  }
}

/// Data record representing a single hotspot entry.
class RecallHotspotEntry {
  final String id;
  final int failures;
  final String decayStage;
  final DateTime lastFailed;

  RecallHotspotEntry({
    required this.id,
    required this.failures,
    required this.decayStage,
    required this.lastFailed,
  });
}
