import 'package:flutter/material.dart';

import '../services/autogen_pipeline_state_service.dart';

/// Control panel for managing the autogen pipeline state.
class AutogenPipelineControlPanelWidget extends StatelessWidget {
  const AutogenPipelineControlPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = AutogenPipelineStateService.getCurrentState();
    return ValueListenableBuilder<AutogenPipelineStatus>(
      valueListenable: notifier,
      builder: (context, status, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: status == AutogenPipelineStatus.ready
                    ? () => notifier.value = AutogenPipelineStatus.publishing
                    : null,
                child: const Text('Start'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: status == AutogenPipelineStatus.publishing
                    ? () => notifier.value = AutogenPipelineStatus.paused
                    : null,
                child: const Text('Pause'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: status != AutogenPipelineStatus.ready
                    ? () => notifier.value = AutogenPipelineStatus.ready
                    : null,
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      },
    );
  }
}
