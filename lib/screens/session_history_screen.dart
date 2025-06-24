import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final notes = context.watch<SessionNoteService>();
    final raw = manager.handsBySession();
    final sessions = _applyFilters(_buildSessions(raw, notes));

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
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      return ListTile(
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
                            if (s.winrate != null)
                              Text(
                                'Winrate: ${s.winrate!.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (s.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  s.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
