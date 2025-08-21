import 'package:flutter/material.dart';
import '../services/booster_adaptation_tuner.dart';
import '../services/recall_success_logger_service.dart';
import '../services/review_streak_evaluator_service.dart';
import '../services/decay_tag_retention_tracker_service.dart';

class DecayAdaptationInsightScreen extends StatefulWidget {
  static const route = '/decay_adaptation_insights';
  const DecayAdaptationInsightScreen({super.key});

  @override
  State<DecayAdaptationInsightScreen> createState() =>
      _DecayAdaptationInsightScreenState();
}

class _RowData {
  final String tag;
  final BoosterAdaptation adaptation;
  final double success;
  final int daysSince;
  final double decay;
  final String reason;
  _RowData({
    required this.tag,
    required this.adaptation,
    required this.success,
    required this.daysSince,
    required this.decay,
    required this.reason,
  });
}

class _DecayAdaptationInsightScreenState
    extends State<DecayAdaptationInsightScreen> {
  bool _loading = true;
  List<_RowData> _rows = [];
  int? _sortColumnIndex;
  bool _ascending = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tuner = BoosterAdaptationTuner.instance;
    final adaptations = await tuner.loadAdaptations();
    final successLogs =
        await RecallSuccessLoggerService.instance.getSuccesses();
    final tagStats = await const ReviewStreakEvaluatorService().getTagStats();
    final decayScores =
        await const DecayTagRetentionTrackerService().getAllDecayScores();

    final successMap = <String, int>{};
    for (final e in successLogs) {
      final tag = e.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      successMap.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }

    final tags = <String>{
      ...adaptations.keys,
      ...tagStats.keys,
      ...decayScores.keys,
      ...successMap.keys,
    }..removeWhere((t) => t.isEmpty);

    final now = DateTime.now();
    final list = <_RowData>[];
    for (final tag in tags) {
      final stats = tagStats[tag];
      final completed = stats?.completedCount ?? 0;
      final successes = successMap[tag] ?? 0;
      final successRate = completed > 0
          ? successes * 100 / completed
          : (successes > 0 ? 100 : 0);
      final last = stats?.lastInteraction;
      final daysSince = last != null ? now.difference(last).inDays : 999;
      final decay = (decayScores[tag] ?? 0.0) * 100;
      final adaptation = adaptations[tag] ?? BoosterAdaptation.keep;

      final tooFrequent = daysSince <= 2 && decay < 30;
      final longDelay = daysSince >= 14 || decay > 60;
      String reason = 'Stable';
      if (successRate > 90 && tooFrequent) {
        reason = 'High recall & frequent review';
      } else if (successRate < 60 || longDelay) {
        reason = 'Low recall or long delay';
      }

      list.add(
        _RowData(
          tag: tag,
          adaptation: adaptation,
          success: successRate,
          daysSince: daysSince,
          decay: decay,
          reason: reason,
        ),
      );
    }
    _sort(list);
    if (!mounted) return;
    setState(() {
      _rows = list;
      _loading = false;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _ascending = ascending;
      _sort(_rows);
    });
  }

  void _sort(List<_RowData> list) {
    int compare<num>(num a, num b) =>
        _ascending ? a.compareTo(b) : b.compareTo(a);
    switch (_sortColumnIndex) {
      case 1:
        list.sort((a, b) => compare(a.adaptation.index, b.adaptation.index));
        break;
      case 2:
        list.sort((a, b) => compare(a.success, b.success));
        break;
      case 3:
        list.sort((a, b) => compare(a.daysSince, b.daysSince));
        break;
      case 4:
        list.sort((a, b) => compare(a.decay, b.decay));
        break;
      default:
        list.sort(
          (a, b) =>
              _ascending ? a.tag.compareTo(b.tag) : b.tag.compareTo(a.tag),
        );
    }
  }

  List<_RowData> get _filtered {
    final query = _searchController.text.toLowerCase();
    return [
      for (final e in _rows)
        if (query.isEmpty || e.tag.toLowerCase().contains(query)) e,
    ];
  }

  Color? _colorFor(BoosterAdaptation a) {
    switch (a) {
      case BoosterAdaptation.increase:
        return Colors.red.withValues(alpha: .2);
      case BoosterAdaptation.reduce:
        return Colors.green.withValues(alpha: .2);
      default:
        return null;
    }
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
        DataColumn(label: const Text('Adaptation'), onSort: _onSort),
        DataColumn(
          label: const Text('Success %'),
          numeric: true,
          onSort: _onSort,
        ),
        DataColumn(
          label: const Text('Days since'),
          numeric: true,
          onSort: _onSort,
        ),
        DataColumn(
          label: const Text('Decay %'),
          numeric: true,
          onSort: _onSort,
        ),
        const DataColumn(label: Text('Reason')),
      ],
      rows: [
        for (final e in _filtered)
          DataRow(
            color: WidgetStateProperty.all(_colorFor(e.adaptation)),
            cells: [
              DataCell(Text(e.tag)),
              DataCell(Text(_adaptationLabel(e.adaptation))),
              DataCell(Text(e.success.toStringAsFixed(0))),
              DataCell(Text('${e.daysSince}')),
              DataCell(Text(e.decay.toStringAsFixed(0))),
              DataCell(Text(e.reason)),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decay Adaptation'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Filter tag'),
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
