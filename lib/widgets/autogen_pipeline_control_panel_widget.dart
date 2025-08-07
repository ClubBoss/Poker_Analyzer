import 'package:flutter/material.dart';

import '../services/autogen_pipeline_state_service.dart';

/// A control panel with buttons to manually update the autogen pipeline state.
class AutogenPipelineControlPanelWidget extends StatelessWidget {
  const AutogenPipelineControlPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AutogenPipelineStatus>(
      valueListenable: AutogenPipelineStateService.getCurrentState(),
      builder: (context, status, _) {
        return Row(
          children: [
            ElevatedButton(
              onPressed: status == AutogenPipelineStatus.publishing
                  ? null
                  : () => AutogenPipelineStateService.getCurrentState().value =
                      AutogenPipelineStatus.publishing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Start'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: status == AutogenPipelineStatus.paused
                  ? null
                  : () => AutogenPipelineStateService.getCurrentState().value =
                      AutogenPipelineStatus.paused,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Pause'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: status == AutogenPipelineStatus.ready
                  ? null
                  : () => AutogenPipelineStateService.getCurrentState().value =
                      AutogenPipelineStatus.ready,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}

