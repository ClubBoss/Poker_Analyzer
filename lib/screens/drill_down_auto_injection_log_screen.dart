import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/theory_auto_injection_log_entry.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_auto_injection_logger_service.dart';

/// Displays detailed log entries for a specific day or lesson.
class DrillDownAutoInjectionLogScreen extends StatefulWidget {
  final DateTime? date;
  final String? lessonId;

  const DrillDownAutoInjectionLogScreen.date(this.date, {super.key})
      : lessonId = null;
  const DrillDownAutoInjectionLogScreen.lesson(this.lessonId, {super.key})
      : date = null;

  @override
  State<DrillDownAutoInjectionLogScreen> createState() =>
      _DrillDownAutoInjectionLogScreenState();
}

class _DrillDownAutoInjectionLogScreenState
    extends State<DrillDownAutoInjectionLogScreen> {
  bool _loading = true;
  final List<TheoryAutoInjectionLogEntry> _logs = [];
  final Map<String, String> _titles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    var logs = await TheoryAutoInjectionLoggerService.instance.getRecentLogs(
      limit: 200,
    );
    if (widget.date != null) {
      final d = widget.date!;
      logs = logs
          .where((l) =>
              l.timestamp.year == d.year &&
              l.timestamp.month == d.month &&
              l.timestamp.day == d.day)
          .toList();
    } else if (widget.lessonId != null) {
      logs = logs.where((l) => l.lessonId == widget.lessonId).toList();
    }
    if (logs.isNotEmpty) {
      await MiniLessonLibraryService.instance.loadAll();
      for (final l in logs) {
        final lesson = MiniLessonLibraryService.instance.getById(l.lessonId);
        _titles[l.lessonId] = lesson?.resolvedTitle ?? l.lessonId;
      }
    }
    _logs.addAll(logs);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.date != null
        ? 'Injections on ${widget.date!.month}/${widget.date!.day}'
        : _titles[widget.lessonId!] ?? widget.lessonId!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No injections'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final lessonTitle = _titles[log.lessonId] ?? log.lessonId;
                    return ListTile(
                      title: Text(lessonTitle),
                      subtitle: Text('Spot: ${log.spotId}'),
                      trailing: Text(
                        timeago.format(
                          log.timestamp,
                          allowFromNow: true,
                          locale: 'en_short',
                        ),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    );
                  },
                ),
    );
  }
}

