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

enum _SortOrder { newestFirst, oldestFirst }

class _DrillDownAutoInjectionLogScreenState
    extends State<DrillDownAutoInjectionLogScreen> {
  bool _loading = true;
  final List<TheoryAutoInjectionLogEntry> _logs = [];
  final List<TheoryAutoInjectionLogEntry> _filtered = [];
  final Map<String, String> _titles = {};
  final TextEditingController _spotIdController = TextEditingController();
  _SortOrder _sortOrder = _SortOrder.newestFirst;
  bool _groupByLesson = false;

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
          .where(
            (l) =>
                l.timestamp.year == d.year &&
                l.timestamp.month == d.month &&
                l.timestamp.day == d.day,
          )
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
    _applyFilters();
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilters() {
    var logs = List<TheoryAutoInjectionLogEntry>.from(_logs);
    final query = _spotIdController.text.trim();
    if (query.isNotEmpty) {
      logs = logs.where((l) => l.spotId.contains(query)).toList();
    }
    logs.sort(
      (a, b) => _sortOrder == _SortOrder.newestFirst
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp),
    );
    _filtered
      ..clear()
      ..addAll(logs);
  }

  @override
  void dispose() {
    _spotIdController.dispose();
    super.dispose();
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
          : _filtered.isEmpty
              ? const Center(child: Text('No injections'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _spotIdController,
                              decoration: const InputDecoration(
                                hintText: 'Filter by spotId',
                                isDense: true,
                              ),
                              onChanged: (_) {
                                setState(_applyFilters);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<_SortOrder>(
                            value: _sortOrder,
                            items: const [
                              DropdownMenuItem(
                                value: _SortOrder.newestFirst,
                                child: Text('Newest First'),
                              ),
                              DropdownMenuItem(
                                value: _SortOrder.oldestFirst,
                                child: Text('Oldest First'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _sortOrder = v;
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Text('Group by lesson'),
                              Switch(
                                value: _groupByLesson,
                                onChanged: (v) {
                                  setState(() => _groupByLesson = v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child:
                          _groupByLesson ? _buildGroupedList() : _buildList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final log = _filtered[index];
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
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        );
      },
    );
  }

  Widget _buildGroupedList() {
    final Map<String, List<TheoryAutoInjectionLogEntry>> grouped = {};
    for (final log in _filtered) {
      grouped.putIfAbsent(log.lessonId, () => []).add(log);
    }
    return ListView(
      children: [
        for (final entry in grouped.entries)
          ExpansionTile(
            title: Text(_titles[entry.key] ?? entry.key),
            children: [
              for (final log in entry.value)
                ListTile(
                  title: Text('Spot: ${log.spotId}'),
                  trailing: Text(
                    timeago.format(
                      log.timestamp,
                      allowFromNow: true,
                      locale: 'en_short',
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
