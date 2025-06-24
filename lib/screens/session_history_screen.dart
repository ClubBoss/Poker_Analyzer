import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../helpers/date_utils.dart';
import '../theme/constants.dart';
import 'session_hands_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  String _dateFilter = 'Все';

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<MapEntry<int, List<SavedHand>>> _filteredSessions(
      Map<int, List<SavedHand>> sessions) {
    final now = DateTime.now();
    final List<MapEntry<int, List<SavedHand>>> visible = [];
    for (final entry in sessions.entries) {
      final hands = entry.value;
      if (hands.isEmpty) continue;
      final date = hands.first.savedAt;
      if (_dateFilter == 'Сегодня' && !_sameDay(date, now)) continue;
      if (_dateFilter == '7 дней' &&
          date.isBefore(now.subtract(const Duration(days: 7)))) {
        continue;
      }
      if (_dateFilter == '30 дней' &&
          date.isBefore(now.subtract(const Duration(days: 30)))) {
        continue;
      }
      visible.add(entry);
    }
    visible.sort((a, b) => b.value.first.savedAt.compareTo(a.value.first.savedAt));
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final sessions = manager.handsBySession();
    final visible = _filteredSessions(sessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История сессий'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding16),
            child: DropdownButton<String>(
              value: _dateFilter,
              dropdownColor: const Color(0xFF2A2B2E),
              onChanged: (v) => setState(() => _dateFilter = v ?? 'Все'),
              items: ['Все', 'Сегодня', '7 дней', '30 дней']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      'Сессии отсутствуют',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sessionId = visible[index].key;
                      final hands = visible[index].value;
                      final date = formatDateTime(hands.first.savedAt);
                      return ListTile(
                        title: Text(
                          'Сессия $sessionId – $date',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${hands.length} раздач',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionHandsScreen(
                                  sessionId: sessionId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Просмотреть'),
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
