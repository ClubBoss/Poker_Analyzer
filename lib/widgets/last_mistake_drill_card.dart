import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../utils/preference_state.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class LastMistakeDrillCard extends StatefulWidget {
  const LastMistakeDrillCard({super.key});

  @override
  State<LastMistakeDrillCard> createState() => _LastMistakeDrillCardState();
}

class _LastMistakeDrillCardState extends State<LastMistakeDrillCard>
    with PreferenceState<LastMistakeDrillCard> {
  static const _key = 'last_mistake_drill_ts';
  int? _ts;

  @override
  void onPrefsLoaded() {
    setState(() => _ts = prefs.getInt(_key));
  }

  Future<void> _mark(int ts) async {
    await prefs.setInt(_key, ts);
    setState(() => _ts = ts);
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final hand = hands.reversed.firstWhereOrNull((h) {
      final ev = h.evLoss ?? 0.0;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      return ev.abs() >= 1.0 && !h.corrected && exp != null && gto != null && exp != gto;
    });
    if (hand == null) return const SizedBox.shrink();
    final ts = hand.savedAt.millisecondsSinceEpoch;
    if (_ts == ts) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final cat = hand.category ?? 'Без категории';
    final ev = hand.evLoss?.abs() ?? 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.bug_report, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Последняя ошибка',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cat, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('-${ev.toStringAsFixed(1)} EV',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = TrainingPackService.createDrillFromHand(hand);
              await context.read<TrainingSessionService>().startSession(tpl);
              await _mark(ts);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                );
              }
            },
            child: const Text('Тренировать'),
          ),
        ],
      ),
    );
  }
}
