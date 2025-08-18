import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/date_utils.dart';
import '../models/v2/training_session.dart';
import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../services/training_stats_service.dart';
import 'session_analysis_screen.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final List<TrainingSession> _sessions = [];
  Box<dynamic>? _box;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _tag;
  String? _template;

  static const _startKey = 'session_history_start';
  static const _endKey = 'session_history_end';
  static const _tagKey = 'session_history_tag';
  static const _tplKey = 'session_history_tpl';

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _load());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = context.read<TrainingStatsService>();
    final startStr = prefs.getString(_startKey);
    final endStr = prefs.getString(_endKey);
    setState(() {
      _startDate = startStr != null ? DateTime.tryParse(startStr) : null;
      _endDate = endStr != null ? DateTime.tryParse(endStr) : null;
      _tag = prefs.getString(_tagKey);
      _template = prefs.getString(_tplKey);
      if (_startDate == null) {
        final days = stats.sessionsDaily(10000);
        if (days.isNotEmpty) _startDate = days.first.key;
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_startDate != null) {
      await prefs.setString(_startKey, _startDate!.toIso8601String());
    } else {
      await prefs.remove(_startKey);
    }
    if (_endDate != null) {
      await prefs.setString(_endKey, _endDate!.toIso8601String());
    } else {
      await prefs.remove(_endKey);
    }
    if (_tag != null && _tag!.isNotEmpty) {
      await prefs.setString(_tagKey, _tag!);
    } else {
      await prefs.remove(_tagKey);
    }
    if (_template != null && _template!.isNotEmpty) {
      await prefs.setString(_tplKey, _template!);
    } else {
      await prefs.remove(_tplKey);
    }
  }

  Future<void> _load() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
    final List<TrainingSession> list = [];
    for (final value in _box!.values) {
      if (value is Map) {
        list.add(TrainingSession.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    setState(() {
      _sessions
        ..clear()
        ..addAll(list);
    });
  }

  List<TrainingSession> get _filtered {
    final manager = context.read<SavedHandManagerService>();
    final hands = manager.hands;
    return [
      for (final s in _sessions)
        if ((_startDate == null || !s.startedAt.isBefore(_startDate!)) &&
            (_endDate == null ||
                !(s.completedAt ?? DateTime.now()).isAfter(_endDate!)) &&
            (_template == null ||
                _template!.isEmpty ||
                s.templateId == _template) &&
            (_tag == null || _tag!.isEmpty
                ? true
                : hands.any(
                    (h) =>
                        !h.savedAt.isBefore(s.startedAt) &&
                        (s.completedAt == null ||
                            !h.savedAt.isAfter(s.completedAt!)) &&
                        h.tags.contains(_tag),
                  )))
          s,
    ];
  }

  Future<void> _exportNotes() async {
    final notes = context.read<SessionNoteService>();
    final stats = context.read<TrainingStatsService>();
    final path = await notes.exportAsPdf(stats);
    if (path == null || !mounted) return;
    final name = path.split(Platform.pathSeparator).last;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Файл сохранён: $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export',
            onPressed: _exportNotes,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: _filtered.isEmpty
          ? const Center(
              child: Text(
                'No sessions',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: _filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final manager = context.watch<SavedHandManagerService>();
                  final tags = manager.allTags.toList()..sort();
                  final templates =
                      _sessions.map((e) => e.templateId).toSet().toList()
                        ..sort();
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _startDate = picked);
                              _savePrefs();
                            }
                          },
                          child: Text(
                            _startDate == null
                                ? 'Start'
                                : formatDate(_startDate!),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _endDate = picked);
                              _savePrefs();
                            }
                          },
                          child: Text(
                            _endDate == null ? 'End' : formatDate(_endDate!),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _tag?.isEmpty ?? true ? null : _tag,
                          hint: const Text('Tag'),
                          dropdownColor: const Color(0xFF2A2B2D),
                          onChanged: (v) {
                            setState(
                              () => _tag = v?.isEmpty ?? true ? null : v,
                            );
                            _savePrefs();
                          },
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All'),
                            ),
                            for (final t in tags)
                              DropdownMenuItem(value: t, child: Text(t)),
                          ],
                        ),
                        DropdownButton<String>(
                          value: _template?.isEmpty ?? true ? null : _template,
                          hint: const Text('Template'),
                          dropdownColor: const Color(0xFF2A2B2D),
                          onChanged: (v) {
                            setState(
                              () => _template = v?.isEmpty ?? true ? null : v,
                            );
                            _savePrefs();
                          },
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All'),
                            ),
                            for (final t in templates)
                              DropdownMenuItem(value: t, child: Text(t)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                final s = _filtered[index - 1];
                final correct = s.results.values.where((e) => e).length;
                return Card(
                  color: const Color(0xFF2A2B2D),
                  child: ListTile(
                    title: Text(
                      s.templateId,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start: ${formatDateTime(s.startedAt)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (s.completedAt != null)
                          Text(
                            'End: ${formatDateTime(s.completedAt!)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        Text(
                          'Correct: $correct / ${s.results.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    final allHands = context
                        .read<SavedHandManagerService>()
                        .hands;
                    final List<SavedHand> sessionHands = [];
                    for (final h in allHands) {
                      final afterStart = !h.savedAt.isBefore(s.startedAt);
                      final beforeEnd =
                          s.completedAt == null ||
                          !h.savedAt.isAfter(s.completedAt!);
                      if (afterStart && beforeEnd) sessionHands.add(h);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionAnalysisScreen(hands: sessionHands),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
