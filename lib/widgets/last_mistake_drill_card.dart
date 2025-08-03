import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../helpers/shared_prefs_helper.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import '../utils/shared_prefs_keys.dart';
import 'drill_card.dart';

class LastMistakeDrillCard extends StatefulWidget {
  const LastMistakeDrillCard({super.key});

  @override
  State<LastMistakeDrillCard> createState() => _LastMistakeDrillCardState();
}

class _LastMistakeDrillCardState extends State<LastMistakeDrillCard> {
  int? _ts;

  @override
  void initState() {
    super.initState();
    SharedPrefsHelper.getInt(SharedPrefsKeys.lastMistakeDrillTs).then((v) {
      if (mounted) setState(() => _ts = v);
    });
  }

  Future<void> _mark(int ts) async {
    await SharedPrefsHelper.setInt(SharedPrefsKeys.lastMistakeDrillTs, ts);
    if (mounted) setState(() => _ts = ts);
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
    final cat = hand.category ?? 'Без категории';
    final ev = hand.evLoss?.abs() ?? 0.0;
    return DrillCard(
      icon: Icons.bug_report,
      title: 'Последняя ошибка',
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('-${ev.toStringAsFixed(1)} EV',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
      onPressed: () async {
        final tpl = TrainingPackService.createDrillFromHand(hand);
        await context.read<TrainingSessionService>().startSession(tpl);
        await _mark(ts);
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TrainingSessionScreen()),
          );
        }
      },
    );
  }
}
