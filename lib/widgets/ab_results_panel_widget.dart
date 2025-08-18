import 'package:flutter/material.dart';

import '../services/autogen_status_dashboard_service.dart';
import '../services/training_run_ab_comparator.dart';

class ABResultsPanelWidget extends StatefulWidget {
  const ABResultsPanelWidget({super.key});

  @override
  State<ABResultsPanelWidget> createState() => _ABResultsPanelWidgetState();
}

class _ABResultsPanelWidgetState extends State<ABResultsPanelWidget> {
  int? _sortColumnIndex;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatusDashboardService.instance;
    return ValueListenableBuilder<List<ABArmResult>>(
      valueListenable: service.abResultsNotifier,
      builder: (context, results, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recommended: '
                  '${results.isNotEmpty ? results.first.armId : '-'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  _buildColumn('Arm', 0, (r) => r.armId),
                  _buildColumn('N', 1, (r) => r.n),
                  _buildColumn('Accuracy', 2, (r) => r.accuracy),
                  _buildColumn('Dropoff', 3, (r) => r.dropoffRate),
                  _buildColumn('Time', 4, (r) => r.timeToComplete),
                  _buildColumn('Novelty', 5, (r) => r.novelty),
                  _buildColumn('Score', 6, (r) => r.compositeScore),
                  _buildColumn('Confidence', 7, (r) => r.confidence),
                ],
                rows: [
                  for (final r in results)
                    DataRow(
                      cells: [
                        DataCell(Text(r.armId)),
                        DataCell(Text(r.n.toString())),
                        DataCell(Text(r.accuracy.toStringAsFixed(2))),
                        DataCell(Text(r.dropoffRate.toStringAsFixed(2))),
                        DataCell(Text(r.timeToComplete.toStringAsFixed(2))),
                        DataCell(Text(r.novelty.toStringAsFixed(2))),
                        DataCell(Text(r.compositeScore.toStringAsFixed(2))),
                        DataCell(Text(r.confidence.toStringAsFixed(2))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildColumn(
    String label,
    int idx,
    Comparable Function(ABArmResult r) selector,
  ) {
    final service = AutogenStatusDashboardService.instance;
    return DataColumn(
      label: Text(label),
      onSort: (i, asc) {
        setState(() {
          _sortColumnIndex = i;
          _sortAscending = asc;
        });
        final list = [...service.abResultsNotifier.value];
        list.sort((a, b) {
          final r = Comparable.compare(selector(a), selector(b));
          return asc ? r : -r;
        });
        service.abResultsNotifier.value = list;
      },
    );
  }

  Future<void> _showSettings() async {
    final comparator = TrainingRunABComparator();
    final weights = await comparator.getWeights();
    final control = await comparator.getControlArm() ?? '';
    final accCtrl = TextEditingController(
      text: weights['accuracy']!.toStringAsFixed(2),
    );
    final dropCtrl = TextEditingController(
      text: weights['dropoff']!.toStringAsFixed(2),
    );
    final timeCtrl = TextEditingController(
      text: weights['time']!.toStringAsFixed(2),
    );
    final novCtrl = TextEditingController(
      text: weights['novelty']!.toStringAsFixed(2),
    );
    final controlCtrl = TextEditingController(text: control);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('A/B Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controlCtrl,
                decoration: const InputDecoration(labelText: 'Control Arm ID'),
              ),
              TextField(
                controller: accCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Accuracy Weight'),
              ),
              TextField(
                controller: dropCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Dropoff Weight'),
              ),
              TextField(
                controller: timeCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Time Weight'),
              ),
              TextField(
                controller: novCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Novelty Weight'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final w = {
                'accuracy': double.tryParse(accCtrl.text) ?? 0.4,
                'dropoff': double.tryParse(dropCtrl.text) ?? 0.25,
                'time': double.tryParse(timeCtrl.text) ?? 0.2,
                'novelty': double.tryParse(novCtrl.text) ?? 0.15,
              };
              await comparator.saveWeights(w);
              await comparator.saveControlArm(controlCtrl.text);
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
