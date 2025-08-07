import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/autogen_pipeline_event_logger_service.dart';
import '../screens/autogen_metrics_dashboard_screen.dart';

/// Compact viewer showing recent autogen pipeline events.
class InlineAutogenEventLogWidget extends StatefulWidget {
  const InlineAutogenEventLogWidget({super.key});

  @override
  State<InlineAutogenEventLogWidget> createState() =>
      _InlineAutogenEventLogWidgetState();
}

class _InlineAutogenEventLogWidgetState
    extends State<InlineAutogenEventLogWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = List<AutogenPipelineEvent>.from(
      AutogenPipelineEventLoggerService.getLog(),
    );
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = events.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recent.isEmpty)
          const Text('No events logged yet')
        else
          for (final e in recent)
            ListTile(
              dense: true,
              leading: Text(DateFormat('HH:mm:ss').format(e.timestamp)),
              title: Text(e.message),
              subtitle: Text(e.type),
            ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AutogenMetricsDashboardScreen(),
                ),
              );
            },
            child: const Text('View Full Log'),
          ),
        ),
      ],
    );
  }
}
