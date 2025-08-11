import 'dart:io';

import 'package:flutter/material.dart';

import '../models/autogen_session_meta.dart';
import '../models/autogen_step_status.dart';
import '../services/autogen_pipeline_session_tracker_service.dart';
import '../services/autogen_status_dashboard_service.dart';

/// Displays a detailed autogen session report inline.
class InlineReportViewerWidget extends StatelessWidget {
  final String sessionId;

  const InlineReportViewerWidget({super.key, required this.sessionId});

  Icon _statusIcon(AutoGenStepStatus step) {
    switch (step.status) {
      case 'ok':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.blue);
    }
  }

  Future<String?> _loadYaml(String packId) async {
    final candidates = [
      'packs/generated/$packId.yaml',
      '$packId.yaml',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        return file.readAsString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusService = AutogenStatusDashboardService.instance;
    final tracker = AutogenPipelineSessionTrackerService.instance;

    return StreamBuilder<List<AutogenSessionMeta>>(
      stream: statusService.watchSessions(),
      initialData: statusService.getRecentSessions(),
      builder: (context, sessionSnap) {
        AutogenSessionMeta? meta;
        final sessions = sessionSnap.data ?? [];
        for (final s in sessions) {
          if (s.sessionId == sessionId) {
            meta = s;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meta != null)
              ExpansionTile(
                title: const Text('Session'),
                initiallyExpanded: true,
                children: [
                  ListTile(title: Text('Pack: ${meta.packId}')),
                  ListTile(title: Text('Started: ${meta.startedAt}')),
                  ListTile(title: Text('Status: ${meta.status}')),
                ],
              ),
            Expanded(
              child: StreamBuilder<List<AutoGenStepStatus>>(
                stream: tracker.watchSession(sessionId),
                initialData: const [],
                builder: (context, stepSnap) {
                  final steps = stepSnap.data ?? [];
                  final errors =
                      steps.where((e) => e.status == 'error').toList();

                  final children = <Widget>[
                    ExpansionTile(
                      title: const Text('Steps'),
                      initiallyExpanded: true,
                      children: steps
                          .map(
                            (s) => ListTile(
                              leading: _statusIcon(s),
                              title: Text(s.stepName),
                            ),
                          )
                          .toList(),
                    ),
                  ];

                  if (errors.isNotEmpty) {
                    children.add(
                      ExpansionTile(
                        title: Text('Errors (${errors.length})'),
                        initiallyExpanded: true,
                        children: errors
                            .map(
                              (e) => ListTile(
                                title: Text(e.stepName),
                                subtitle: e.errorMessage != null
                                    ? Text(e.errorMessage!)
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }

                  if (meta != null) {
                    children.add(
                      FutureBuilder<String?>(
                        future: _loadYaml(meta.packId),
                        builder: (context, yamlSnap) {
                          final yaml = yamlSnap.data;
                          if (yaml == null || yaml.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return ExpansionTile(
                            title: const Text('YAML'),
                            children: [
                              SizedBox(
                                height: 200,
                                child: SingleChildScrollView(
                                  child: SelectableText(yaml),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  return ListView(children: children);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

