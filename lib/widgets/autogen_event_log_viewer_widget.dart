import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/autogen_pipeline_event_logger_service.dart';

/// Scrollable viewer for autogen pipeline event log.
class AutogenEventLogViewerWidget extends StatefulWidget {
  const AutogenEventLogViewerWidget({super.key});

  @override
  State<AutogenEventLogViewerWidget> createState() =>
      _AutogenEventLogViewerWidgetState();
}

class _AutogenEventLogViewerWidgetState
    extends State<AutogenEventLogViewerWidget> {
  final Set<String> _filters = {};
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
    final types = events.map((e) => e.type).toSet().toList()..sort();
    final filteredEvents = _filters.isEmpty
        ? events
        : events.where((e) => _filters.contains(e.type)).toList();

    final grouped = <String, List<AutogenPipelineEvent>>{};
    for (final e in filteredEvents) {
      grouped.putIfAbsent(e.type, () => []).add(e);
    }

    final items = <Object>[];
    for (final type in grouped.keys) {
      items.add(type);
      items.addAll(grouped[type]!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final t in types)
              FilterChip(
                label: Text(t),
                selected: _filters.contains(t),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _filters.add(t);
                    } else {
                      _filters.remove(t);
                    }
                  });
                },
              ),
            TextButton(
              onPressed: () {
                AutogenPipelineEventLoggerService.clearLog();
                setState(() {});
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }
              final e = item as AutogenPipelineEvent;
              final time = DateFormat('HH:mm:ss').format(e.timestamp);
              return ListTile(
                leading: Text(time),
                title: Text(e.message),
                subtitle: Text(e.type),
              );
            },
          ),
        ),
      ],
    );
  }
}
