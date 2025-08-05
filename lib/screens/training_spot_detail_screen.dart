import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../widgets/action_history_widget.dart';
import '../widgets/eval_result_view.dart';
import 'package:provider/provider.dart';
import '../services/training_session_controller.dart';
import 'training_play_screen.dart';
import '../widgets/sync_status_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/theory_mini_lesson_navigator.dart';

class TrainingSpotDetailScreen extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingSpotDetailScreen({super.key, required this.spot});

  Map<int, String> _posMap() => {
        for (int i = 0; i < spot.numberOfPlayers; i++)
          if (i < spot.positions.length) i: spot.positions[i]
      };

  @override
  Widget build(BuildContext context) {
    final heroCards = spot.heroIndex < spot.playerCards.length
        ? spot.playerCards[spot.heroIndex].join(' ')
        : '';
    final board = spot.boardCards.map((c) => c.toString()).join(' ');
    final pos = spot.heroIndex < spot.positions.length
        ? spot.positions[spot.heroIndex]
        : '';
    final user = spot.userAction;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.spotDetails),
        centerTitle: true,
        actions: [
          if (spot.inlineLessons.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: () => TheoryMiniLessonNavigator.instance
                  .openLessonById(spot.inlineLessons.first),
            ),
          SyncStatusIcon.of(context)
        ],
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.heroPosition(pos),
              style: const TextStyle(color: Colors.white)),
      if (heroCards.isNotEmpty)
        Text(l.heroCards(heroCards),
            style: const TextStyle(color: Colors.white)),
      if (board.isNotEmpty)
        Text(l.boardLabel(board), style: const TextStyle(color: Colors.white)),
      const SizedBox(height: 16),
      ActionHistoryWidget(actions: spot.actions, playerPositions: _posMap()),
      if (user != null) ...[
        const SizedBox(height: 16),
        Text(l.yourAction(user),
            style: const TextStyle(color: Colors.white)),
      ],
      Builder(builder: (context) {
        double? ev;
        double? icm;
        for (final a in spot.actions) {
          if (a.playerIndex == spot.heroIndex && a.street == 0) {
            ev ??= a.ev;
            icm ??= a.icmEv;
          }
        }
        if (ev == null && icm == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.evIcm(ev?.toStringAsFixed(2) ?? '-', icm?.toStringAsFixed(2) ?? '-'),
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }),
      if (spot.recommendedAction != null) ...[
        const SizedBox(height: 8),
        EvalResultView(spot: spot, action: user ?? ''),
      ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<TrainingSessionController>().replaySpot(spot);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainingPlayScreen()),
          );
        },
        child: const Icon(Icons.replay),
      ),
    );
  }
}
