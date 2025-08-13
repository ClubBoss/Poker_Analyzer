import 'package:flutter/material.dart';

import '../services/autogen_status_dashboard_service.dart';
import '../services/pack_library_service.dart';

class PackFingerprintComparerReportUI extends StatefulWidget {
  const PackFingerprintComparerReportUI({super.key});

  @override
  State<PackFingerprintComparerReportUI> createState() =>
      _PackFingerprintComparerReportUIState();
}

class _PackFingerprintComparerReportUIState
    extends State<PackFingerprintComparerReportUI> {
  final _statusService = AutogenStatusDashboardService.instance;
  final _searchController = TextEditingController();
  List<DuplicatePackInfo> _all = [];
  String _reasonFilter = 'All';
  String _search = '';
  int _sortColumnIndex = 2;
  bool _sortAscending = false; // default to descending
  final Map<String, String> _packNames = {};

  @override
  void initState() {
    super.initState();
    _all = _statusService.duplicatesNotifier.value;
    _statusService.duplicatesNotifier.addListener(_onDataChanged);
    _prefetchNames(_all);
  }

  void _onDataChanged() {
    setState(() {
      _all = _statusService.duplicatesNotifier.value;
    });
    _prefetchNames(_all);
  }

  Future<void> _prefetchNames(List<DuplicatePackInfo> list) async {
    final ids = <String>{};
    for (final d in list) {
      ids.add(d.candidateId);
      ids.add(d.existingId);
    }
    for (final id in ids) {
      if (_packNames.containsKey(id)) continue;
      final tpl = await PackLibraryService.instance.getById(id);
      if (tpl != null && mounted) {
        setState(() {
          _packNames[id] = tpl.name;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statusService.duplicatesNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  List<DuplicatePackInfo> get _filtered {
    final q = _search.toLowerCase();
    final filtered = _all.where((d) {
      if (_reasonFilter != 'All' && d.reason != _reasonFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final candName = _packNames[d.candidateId]?.toLowerCase() ?? '';
      final existName = _packNames[d.existingId]?.toLowerCase() ?? '';
      return d.candidateId.toLowerCase().contains(q) ||
          d.existingId.toLowerCase().contains(q) ||
          candName.contains(q) ||
          existName.contains(q);
    }).toList();
    filtered.sort((a, b) => _sortAscending
        ? a.similarity.compareTo(b.similarity)
        : b.similarity.compareTo(a.similarity));
    return filtered;
  }

  void _showDetails(DuplicatePackInfo info) async {
    final cand = await PackLibraryService.instance.getById(info.candidateId);
    final exist = await PackLibraryService.instance.getById(info.existingId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pack Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidate: ${cand?.name ?? info.candidateId}'),
            Text('Existing: ${exist?.name ?? info.existingId}'),
            Text('Similarity: ${(info.similarity * 100).toStringAsFixed(1)}%'),
            Text('Reason: ${info.reason}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Packs Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _reasonFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                        value: 'duplicate', child: Text('duplicate')),
                    DropdownMenuItem(
                        value: 'high_similarity',
                        child: Text('high_similarity')),
                  ],
                  onChanged: (v) => setState(() {
                    _reasonFilter = v!;
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by ID or Name',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() {
                      _search = v;
                    }),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No duplicates detected'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: PaginatedDataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columns: [
                        const DataColumn(label: Text('Candidate ID')),
                        const DataColumn(label: Text('Existing ID')),
                        DataColumn(
                          label: const Text('Similarity %'),
                          numeric: true,
                          onSort: (i, asc) => setState(() {
                            _sortColumnIndex = i;
                            _sortAscending = asc;
                          }),
                        ),
                        const DataColumn(label: Text('Reason')),
                      ],
                      source: _DupDataSource(data, _showDetails),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DupDataSource extends DataTableSource {
  final List<DuplicatePackInfo> data;
  final void Function(DuplicatePackInfo info) onTap;

  _DupDataSource(this.data, this.onTap);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final d = data[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(d.candidateId)),
        DataCell(Text(d.existingId)),
        DataCell(Text((d.similarity * 100).toStringAsFixed(1))),
        DataCell(Text(d.reason)),
      ],
      onSelectChanged: (_) => onTap(d),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
