import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/autogen_realtime_stats_panel.dart';
import '../widgets/inline_report_viewer_widget.dart';
import '../services/autogen_status_dashboard_service.dart';
import '../services/autogen_pipeline_executor.dart';
import '../services/training_pack_auto_generator.dart';

enum _AutogenStatus { idle, running, completed, stopped }

/// Debug screen that monitors autogeneration progress and controls the pipeline.
class AutogenDebugScreen extends StatefulWidget {
  const AutogenDebugScreen({super.key});

  @override
  State<AutogenDebugScreen> createState() => _AutogenDebugScreenState();
}

class _AutogenDebugScreenState extends State<AutogenDebugScreen> {
  _AutogenStatus _status = _AutogenStatus.idle;
  TrainingPackAutoGenerator? _generator;

  void _startAutogen() {
    if (_status == _AutogenStatus.running) return;
    final dashboard = AutogenStatusDashboardService.instance;
    dashboard.start();
    final generator = TrainingPackAutoGenerator();
    _generator = generator;
    final executor = AutogenPipelineExecutor(
      generator: generator,
      dashboard: dashboard,
    );
    setState(() {
      _status = _AutogenStatus.running;
    });
    Future(() async {
      await executor.execute(const []);
      if (mounted && _status == _AutogenStatus.running) {
        setState(() => _status = _AutogenStatus.completed);
      }
    });
  }

  void _stopAutogen() {
    _generator?.abort();
    if (mounted) {
      setState(() => _status = _AutogenStatus.stopped);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Autogen Debug')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _status == _AutogenStatus.running ? null : _startAutogen,
                  child: const Text('Start Autogen'),
                ),
                OutlinedButton(
                  onPressed:
                      _status == _AutogenStatus.running ? _stopAutogen : null,
                  child: const Text('Stop'),
                ),
                Text('Status: ${_status.name}'),
              ],
            ),
          ),
          Expanded(child: Container()),
          const AutogenRealtimeStatsPanel(),
          const SizedBox(
            height: 200,
            child: InlineReportViewerWidget(),
          ),
        ],
      ),
    );
  }
}

