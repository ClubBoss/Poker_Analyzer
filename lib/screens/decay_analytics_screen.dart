import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/decay_analytics_export.dart';
import '../services/decay_analytics_exporter_service.dart';
import '../services/booster_adaptation_tuner.dart';

class DecayAnalyticsScreen extends StatefulWidget {
  static const route = '/decay_analytics';
  const DecayAnalyticsScreen({super.key});

  @override
  State<DecayAnalyticsScreen> createState() => _DecayAnalyticsScreenState();
}

class _DecayAnalyticsScreenState extends State<DecayAnalyticsScreen> {
  bool _loading = true;
  List<DecayAnalyticsExport> _data = [];
  int? _sortColumnIndex;
  bool _ascending = false;
  final _searchController = TextEditingController();
  BoosterAdaptation? _adaptation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await const DecayAnalyticsExporterService().exportAnalytics();
    setState(() {
      _data = list;
      _loading = false;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _ascending = ascending;
      _sort(_data);
    });
  }

  void _sort(List<DecayAnalyticsExport> list) {
    int compare<num>(num a, num b) =>
        _ascending ? a.compareTo(b) : b.compareTo(a);
    switch (_sortColumnIndex) {
      case 1:
        list.sort((a, b) => compare(a.decay, b.decay));
        break;
      case 3:
        list.sort((a, b) => compare(
              a.lastInteraction?.millisecondsSinceEpoch ?? 0,
              b.lastInteraction?.millisecondsSinceEpoch ?? 0,
            ));
        break;
      case 4:
        list.sort((a, b) => compare(
            a.recommendedDaysUntilReview, b.recommendedDaysUntilReview));
        break;
      default:
        list.sort((a, b) =>
            _ascending ? a.tag.compareTo(b.tag) : b.tag.compareTo(a.tag));
    }
  }

  List<DecayAnalyticsExport> get _filtered {
    final query = _searchController.text.toLowerCase();
    return [
      for (final e in _data)
        if ((query.isEmpty || e.tag.toLowerCase().contains(query)) &&
            (_adaptation == null || e.adaptation == _adaptation))
          e
    ];
  }

  String _adaptationLabel(BoosterAdaptation a) {
    switch (a) {
      case BoosterAdaptation.increase:
        return 'Increase';
      case BoosterAdaptation.reduce:
        return 'Reduce';
      case BoosterAdaptation.keep:
      default:
        return 'Keep';
    }
  }

  DataTable _table() {
    return DataTable(
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _ascending,
      columns: [
        DataColumn(label: const Text('Tag'), onSort: _onSort),
        DataColumn(
            label: const Text('Decay %'), numeric: true, onSort: _onSort),
        const DataColumn(label: Text('Adaptation')),
        DataColumn(label: const Text('Last Interaction'), onSort: _onSort),
        DataColumn(
            label: const Text('Recommended Days'),
            numeric: true,
            onSort: _onSort),
      ],
      rows: [
        for (final e in _filtered)
          DataRow(cells: [
            DataCell(Text(e.tag)),
            DataCell(Text((e.decay * 100).toStringAsFixed(0))),
            DataCell(Text(_adaptationLabel(e.adaptation))),
            DataCell(Text(e.lastInteraction != null
                ? DateFormat('yyyy-MM-dd').format(e.lastInteraction!)
                : '-')),
            DataCell(Text('${e.recommendedDaysUntilReview}')),
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decay Analytics'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration:
                            const InputDecoration(hintText: 'Filter tag'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<BoosterAdaptation?>(
                      value: _adaptation,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(
                            value: BoosterAdaptation.increase,
                            child: Text('Increase')),
                        DropdownMenuItem(
                            value: BoosterAdaptation.reduce,
                            child: Text('Reduce')),
                        DropdownMenuItem(
                            value: BoosterAdaptation.keep, child: Text('Keep')),
                      ],
                      onChanged: (v) => setState(() => _adaptation = v),
                    ),
                  ],
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
