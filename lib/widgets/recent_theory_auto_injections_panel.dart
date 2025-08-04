import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../services/theory_auto_injection_logger_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../models/theory_auto_injection_log_entry.dart';

/// Displays recent theory auto-injection events for debugging/analytics.
class RecentTheoryAutoInjectionsPanel extends StatefulWidget {
  const RecentTheoryAutoInjectionsPanel({super.key});

  @override
  State<RecentTheoryAutoInjectionsPanel> createState() =>
      _RecentTheoryAutoInjectionsPanelState();
}

class _RecentTheoryAutoInjectionsPanelState
    extends State<RecentTheoryAutoInjectionsPanel> {
  bool _loading = true;
  List<TheoryAutoInjectionLogEntry> _logs = [];
  final Map<String, String> _titles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final logs = await TheoryAutoInjectionLoggerService.instance.getRecentLogs(
      limit: 10,
    );
    _logs = logs;
    if (_logs.isNotEmpty) {
      await MiniLessonLibraryService.instance.loadAll();
      for (final l in _logs) {
        final lesson = MiniLessonLibraryService.instance.getById(l.lessonId);
        _titles[l.lessonId] = lesson?.resolvedTitle ?? l.lessonId;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('No recent injections'));
    }
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final title = _titles[log.lessonId] ?? log.lessonId;
        return ListTile(
          title: Text(title),
          subtitle: Text('Spot: ${log.spotId}'),
          trailing: Text(
            timeago.format(
              log.timestamp,
              allowFromNow: true,
              locale: 'en_short',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        );
      },
    );
  }
}
