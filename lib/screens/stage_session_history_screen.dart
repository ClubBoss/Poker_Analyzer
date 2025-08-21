import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../services/session_log_service.dart';
import 'session_log_detail_screen.dart';

class StageSessionHistoryScreen extends StatefulWidget {
  final String stageId;
  const StageSessionHistoryScreen({super.key, required this.stageId});

  @override
  State<StageSessionHistoryScreen> createState() =>
      _StageSessionHistoryScreenState();
}

class _StageSessionHistoryScreenState extends State<StageSessionHistoryScreen> {
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final logs = context
        .watch<SessionLogService>()
        .logs
        .where((l) => l.templateId == widget.stageId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final tags = <String>{for (final l in logs) ...l.categories.keys};
    var visibleLogs = logs;
    if (_selectedTags.isNotEmpty) {
      visibleLogs = logs
          .where((l) => l.categories.keys.any(_selectedTags.contains))
          .toList();
    }

    final Widget body = visibleLogs.isEmpty
        ? const Center(
            child: Text('No sessions', style: TextStyle(color: Colors.white54)),
          )
        : ListView.builder(
            itemCount: visibleLogs.length,
            itemBuilder: (context, index) {
              final log = visibleLogs[index];
              final total = log.correctCount + log.mistakeCount;
              final acc = total == 0 ? 0.0 : log.correctCount / total * 100;
              final ev = log.evPercent;
              final evText = ev != null ? ev.toStringAsFixed(1) : '-';
              final cats = log.categories.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final tagText = cats.isEmpty
                  ? null
                  : cats.map((e) => e.key).take(3).join(', ');
              return Card(
                color: const Color(0xFF2A2B2D),
                child: ListTile(
                  title: Text(
                    formatDate(log.completedAt),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acc ${acc.toStringAsFixed(1)}% · $total рук · EV $evText%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (tagText != null)
                        Text(
                          tagText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionDetailScreen(logId: log.sessionId),
                      ),
                    );
                  },
                ),
              );
            },
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Column(
        children: [
          if (tags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final t in tags)
                    FilterChip(
                      label: Text(t),
                      selected: _selectedTags.contains(t),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTags.add(t);
                          } else {
                            _selectedTags.remove(t);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
