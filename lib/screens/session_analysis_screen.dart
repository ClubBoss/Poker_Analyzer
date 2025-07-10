import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../helpers/hand_utils.dart';
import '../services/push_fold_ev_service.dart';
import '../services/icm_push_ev_service.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../theme/app_colors.dart';

class SessionAnalysisScreen extends StatelessWidget {
  final List<SavedHand> hands;
  const SessionAnalysisScreen({super.key, required this.hands});

  ActionEntry? _heroAction(SavedHand h) {
    for (final a in h.actions) {
      if (a.playerIndex == h.heroIndex) return a;
    }
    return null;
  }

  String? _handCode(SavedHand h) {
    if (h.playerCards.length <= h.heroIndex) return null;
    final cards = h.playerCards[h.heroIndex];
    if (cards.length < 2) return null;
    return handCode('${cards[0].rank}${cards[0].suit} ${cards[1].rank}${cards[1].suit}');
  }

  double? _ev(SavedHand h) {
    final act = _heroAction(h);
    if (act == null) return null;
    var ev = act.ev;
    if (ev == null && act.action.toLowerCase() == 'push') {
      final code = _handCode(h);
      final stack = h.stackSizes[h.heroIndex];
      if (code != null && stack != null) {
        ev = computePushEV(
          heroBbStack: stack,
          bbCount: h.numberOfPlayers - 1,
          heroHand: code,
          anteBb: h.anteBb,
        );
      }
    }
    return ev;
  }

  double? _icm(SavedHand h, double? ev) {
    final act = _heroAction(h);
    if (act == null) return null;
    var icm = act.icmEv;
    if (icm == null && act.action.toLowerCase() == 'push') {
      final code = _handCode(h);
      if (code != null && ev != null) {
        final stacks = [
          for (int i = 0; i < h.numberOfPlayers; i++)
            h.stackSizes[i] ?? 0
        ];
        icm = computeIcmPushEV(
          chipStacksBb: stacks,
          heroIndex: h.heroIndex,
          heroHand: code,
          chipPushEv: ev,
        );
      }
    }
    return icm;
  }

  @override
  Widget build(BuildContext context) {
    final list = [...hands]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    int correct = 0;
    int mistakes = 0;
    for (final h in list) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null) {
        if (exp == gto) {
          correct++;
        } else {
          mistakes++;
        }
      }
    }
    final accuracy = correct + mistakes > 0
        ? correct * 100 / (correct + mistakes)
        : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Analysis')),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hands: ${list.length}',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Accuracy: ${accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Mistakes: $mistakes',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final h in list) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(h.name, style: const TextStyle(color: Colors.white)),
                subtitle: Builder(
                  builder: (context) {
                    final ev = _ev(h);
                    final icm = _icm(h, ev);
                    final evStr = ev == null
                        ? '--'
                        : ev.toStringAsFixed(2);
                    final icmStr = icm == null
                        ? '--'
                        : icm.toStringAsFixed(2);
                    return Text('EV: $evStr • ICM: $icmStr',
                        style: const TextStyle(color: Colors.white70));
                  },
                ),
                onTap: () => showSavedHandViewerDialog(context, h),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
