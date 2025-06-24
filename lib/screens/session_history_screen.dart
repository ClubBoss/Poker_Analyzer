import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../services/session_pin_service.dart';
import '../helpers/date_utils.dart';
import '../theme/constants.dart';
import 'session_hands_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionInfo {
  final int id;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final int hands;
  final int correct;
  final int incorrect;
  final double? winrate;
  final String note;

  _SessionInfo({
    required this.id,
    required this.start,
    required this.end,
    required this.duration,
    required this.hands,
    required this.correct,
    required this.incorrect,
    required this.winrate,
    required this.note,
  });
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final TextEditingController _minDurationCtrl = TextEditingController();
  final TextEditingController _maxDurationCtrl = TextEditingController();
  final TextEditingController _minHandsCtrl = TextEditingController();
  bool _onlyWithNotes = false;

  @override
  void dispose() {
    _minDurationCtrl.dispose();
    _maxDurationCtrl.dispose();
    _minHandsCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}ч');
    parts.add('${minutes}м');
    return parts.join(' ');
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy < 60) return Colors.redAccent;
    if (accuracy < 85) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  List<_SessionInfo> _buildSessions(
      Map<int, List<SavedHand>> data, SessionNoteService notes) {
    final List<_SessionInfo> sessions = [];
    for (final entry in data.entries) {
      final id = entry.key;
      final hands = entry.value..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      if (hands.isEmpty) continue;
      final start = hands.last.savedAt;
      final end = hands.first.savedAt;
      final duration = end.difference(start);
      int correct = 0;
      int incorrect = 0;
      for (final h in hands) {
        final expected = h.expectedAction;
        final gto = h.gtoAction;
        if (expected != null && gto != null) {
          if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
            correct++;
          } else {
            incorrect++;
          }
        }
      }
      final total = correct + incorrect;
      final winrate = total > 0 ? (correct / total * 100) : null;
      final note = notes.noteFor(id);
      sessions.add(_SessionInfo(
        id: id,
        start: start,
        end: end,
        duration: duration,
        hands: hands.length,
        correct: correct,
        incorrect: incorrect,
        winrate: winrate,
        note: note,
      ));
    }
    sessions.sort((a, b) => b.end.compareTo(a.end));
    return sessions;
  }

  List<_SessionInfo> _applyFilters(List<_SessionInfo> sessions) {
    final minDuration =
        double.tryParse(_minDurationCtrl.text) ?? 0;
    final maxDuration =
        double.tryParse(_maxDurationCtrl.text);
    final minHands = int.tryParse(_minHandsCtrl.text) ?? 0;

    return sessions.where((s) {
      final minutes = s.duration.inMinutes;
      if (minutes < minDuration) return false;
      if (maxDuration != null && maxDuration > 0 && minutes > maxDuration) {
        return false;
      }
      if (s.hands < minHands) return false;
      if (_onlyWithNotes && s.note.isEmpty) return false;
      return true;
    }).toList();
  }

  bool _filtersApplied() {
    final minDur = double.tryParse(_minDurationCtrl.text) ?? 0;
    final maxDur = double.tryParse(_maxDurationCtrl.text) ?? 0;
    final minHands = int.tryParse(_minHandsCtrl.text) ?? 0;
    return minDur > 0 || maxDur > 0 || minHands > 0 || _onlyWithNotes;
  }

  Future<void> _exportFilteredMarkdown(
      BuildContext context, List<_SessionInfo> sessions) async {
    if (sessions.isEmpty) return;
    final manager = context.read<SavedHandManagerService>();
    final noteService = context.read<SessionNoteService>();
    final ids = [for (final s in sessions) s.id];
    final notesMap = {for (final id in ids) id: noteService.noteFor(id)};
    final path = await manager.exportSessionsMarkdown(ids, notesMap);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)],
        text: 'training_summary_filtered.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Файл сохранён: training_summary_filtered.md')));
    }
  }

  Future<void> _exportFilteredPdf(
      BuildContext context, List<_SessionInfo> sessions) async {
    if (sessions.isEmpty) return;
    final manager = context.read<SavedHandManagerService>();
    final noteService = context.read<SessionNoteService>();
    final ids = [for (final s in sessions) s.id];
    final notesMap = {for (final id in ids) id: noteService.noteFor(id)};
    final path = await manager.exportSessionsPdf(ids, notesMap);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)],
        text: 'training_summary_filtered.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Файл сохранён: training_summary_filtered.pdf')));
    }
  }

  Future<void> _exportAllMarkdown(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final noteService = context.read<SessionNoteService>();
    final notesMap = {
      for (final id in manager.handsBySession().keys) id: noteService.noteFor(id)
    };
    final path = await manager.exportAllSessionsMarkdown(notesMap);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'training_summary.md');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: training_summary.md')),
      );
    }
  }

  Future<void> _exportAllPdf(BuildContext context) async {
    final manager = context.read<SavedHandManagerService>();
    final noteService = context.read<SessionNoteService>();
    final notesMap = {
      for (final id in manager.handsBySession().keys) id: noteService.noteFor(id)
    };
    final path = await manager.exportAllSessionsPdf(notesMap);
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'training_summary.pdf');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён: training_summary.pdf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final notes = context.watch<SessionNoteService>();
    final pins = context.watch<SessionPinService>();
    final raw = manager.handsBySession();
    final sessions = _applyFilters(_buildSessions(raw, notes));
    final ordered = [
      for (final s in sessions)
        if (pins.isPinned(s.id)) s
    ]
      ..addAll([
        for (final s in sessions)
          if (!pins.isPinned(s.id)) s
      ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История сессий'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minDurationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Мин. длительность (мин)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxDurationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Макс. длительность (мин)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minHandsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Мин. раздач',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Checkbox(
                            value: _onlyWithNotes,
                            onChanged: (v) =>
                                setState(() => _onlyWithNotes = v ?? false),
                          ),
                          const Text('Только с заметкой'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _exportAllMarkdown(context),
                        child: const Text('Экспорт в Markdown'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _exportAllPdf(context),
                        child: const Text('Экспорт в PDF'),
                      ),
                    ),
                  ],
                ),
                if (_filtersApplied()) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _exportFilteredMarkdown(context, sessions),
                          child:
                              const Text('Экспорт отфильтрованных в Markdown'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _exportFilteredPdf(context, sessions),
                          child: const Text('Экспорт отфильтрованных в PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Text(
                      'Сессии отсутствуют',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    itemCount: ordered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = ordered[index];
                      return Dismissible(
                        key: ValueKey(s.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final removed =
                              await manager.removeSession(s.id);
                          await pins.setPinned(s.id, false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Сессия удалена'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    await manager.restoreSession(removed);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: pins.isPinned(s.id)
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                pins.isPinned(s.id)
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  pins.setPinned(s.id, !pins.isPinned(s.id)),
                            ),
                            title: Text(
                              formatDateTime(s.end),
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Длительность: ${_formatDuration(s.duration)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Раздач: ${s.hands} • Верно: ${s.correct} • Ошибки: ${s.incorrect}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (s.winrate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Точность: ${s.winrate!.toStringAsFixed(1)}%',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 2),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: s.winrate! / 100,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _accuracyColor(s.winrate!),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                                if (s.note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      s.note,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(color: Colors.white54),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SessionHandsScreen(sessionId: s.id),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
