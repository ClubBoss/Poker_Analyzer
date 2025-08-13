import 'package:flutter/material.dart';

import '../services/autogen_pipeline_state_service.dart';

/// A small badge widget displaying the current autogen pipeline status.
class AutogenPipelineStatusBadgeWidget extends StatelessWidget {
  const AutogenPipelineStatusBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AutogenPipelineStatus>(
      valueListenable: AutogenPipelineStateService.getCurrentState(),
      builder: (context, status, _) {
        final color = _statusColor(status);
        final label = _statusLabel(status);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Color _statusColor(AutogenPipelineStatus status) {
    switch (status) {
      case AutogenPipelineStatus.ready:
        return Colors.green;
      case AutogenPipelineStatus.paused:
        return Colors.orange;
      case AutogenPipelineStatus.publishing:
        return Colors.blue;
      case AutogenPipelineStatus.error:
        return Colors.red;
    }
  }

  String _statusLabel(AutogenPipelineStatus status) {
    switch (status) {
      case AutogenPipelineStatus.ready:
        return 'Ready';
      case AutogenPipelineStatus.paused:
        return 'Paused';
      case AutogenPipelineStatus.publishing:
        return 'Publishing';
      case AutogenPipelineStatus.error:
        return 'Error';
    }
  }
}
