import 'package:flutter/material.dart';

import '../services/autogen_pipeline_executor_status_service.dart';

/// Simple control panel to start/stop the autogen pipeline and display status.
class AutogenDebugControlPanelWidget extends StatelessWidget {
  const AutogenDebugControlPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AutogenPipelineExecutorStatusService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: service.isRunning,
      builder: (context, running, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: running ? null : service.startAutogen,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: running ? service.stopAutogen : null,
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 16),
                Text('Status: ${running ? 'Running' : 'Idle'}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
