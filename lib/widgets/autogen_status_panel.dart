import 'package:flutter/material.dart';

import '../services/autogen_status_dashboard_service.dart';
import '../services/autogen_pipeline_executor_status_service.dart';
import '../models/autogen_status.dart';

/// Displays real-time status of the autogen pipeline and basic controls.
class AutogenStatusPanel extends StatefulWidget {
  const AutogenStatusPanel({super.key});

  @override
  State<AutogenStatusPanel> createState() => _AutogenStatusPanelState();
}

class _AutogenStatusPanelState extends State<AutogenStatusPanel> {
  final _service = AutogenStatusDashboardService.instance;
  final _execService = AutogenPipelineExecutorStatusService.instance;

  @override
  void initState() {
    super.initState();
    _service.loadSummaries();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AutogenStatus>(
      valueListenable: _service.pipelineStatus,
      builder: (context, status, _) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('State: ${status.state.name}'),
                Text('Step: ${status.currentStep}'),
                Text('Queue: ${status.queueDepth}'),
                Text('Processed: ${status.processed}'),
                Text('Errors: ${status.errorsCount}'),
                Text('ETA: ${_formatDuration(status.eta)}'),
                ValueListenableBuilder<Map<String, int>>(
                  valueListenable: _service.coverageHistogramNotifier,
                  builder: (context, hist, _) {
                    final summary = hist.entries
                        .map((e) => '${e.key}:${e.value}')
                        .join(', ');
                    return Text('Coverage: $summary');
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _service.rejectedByCoverageNotifier,
                  builder: (context, count, _) =>
                      Text('Rejected by coverage: $count'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: status.state == AutogenRunState.idle
                          ? _execService.startAutogen
                          : null,
                      child: const Text('Start'),
                    ),
                    ElevatedButton(
                      onPressed: status.state == AutogenRunState.running
                          ? _execService.stopAutogen
                          : null,
                      child: const Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: status.state == AutogenRunState.paused
                          ? _execService.startAutogen
                          : null,
                      child: const Text('Resume'),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Details'),
                  children: [
                    if (_service.recentErrors.isNotEmpty) ...[
                      const Text('Recent Errors'),
                      for (final e in _service.recentErrors)
                        Text(e, style: const TextStyle(color: Colors.red)),
                    ],
                    if (_service.runSummaries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Run Summaries'),
                      for (final r in _service.runSummaries)
                        Text(
                            '${r.startedAt?.toIso8601String() ?? ''}: processed ${r.processed}, errors ${r.errorsCount}'),
                    ],
                    if (_service.coverageSummaries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Coverage Summaries'),
                      for (final h in _service.coverageSummaries)
                        Text(h.entries
                            .map((e) => '${e.key}:${e.value}')
                            .join(', ')),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
