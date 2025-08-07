import 'package:flutter/material.dart';

import '../models/autogen_step_status.dart';
import '../services/autogen_pipeline_session_tracker_service.dart';

/// Displays real-time progress of autogen steps for a given session.
class AutogenPipelineProgressMonitor extends StatelessWidget {
  final String sessionId;

  const AutogenPipelineProgressMonitor({super.key, required this.sessionId});

  Icon _buildIcon(AutoGenStepStatus step) {
    switch (step.status) {
      case 'ok':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AutoGenStepStatus>>(
      stream: AutogenPipelineSessionTrackerService.instance.watchSession(sessionId),
      initialData: const [],
      builder: (context, snapshot) {
        final steps = snapshot.data ?? [];
        return ListView(
          shrinkWrap: true,
          children: steps.map((step) {
            final tile = ListTile(
              leading: _buildIcon(step),
              title: Text(step.stepName),
            );
            if (step.status == 'error' && step.errorMessage != null) {
              return Tooltip(message: step.errorMessage!, child: tile);
            }
            return tile;
          }).toList(),
        );
      },
    );
  }
}
