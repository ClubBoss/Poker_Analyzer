import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../models/action_entry.dart';
import '../models/saved_hand.dart';
import '../models/card_model.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template.dart';
import '../services/training_pack_storage_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';

import '../services/spot_of_the_day_service.dart';
import '../widgets/spot_of_the_day_card.dart';
import '../widgets/streak_chart.dart';
import '../widgets/daily_progress_ring.dart';
import '../widgets/repeat_mistakes_card.dart';
import '../widgets/weekly_challenge_card.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/quick_continue_card.dart';
import '../widgets/progress_summary_box.dart';
import 'training_progress_analytics_screen.dart';
import '../helpers/training_onboarding.dart';
import '../widgets/sync_status_widget.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotOfTheDayService>().ensureTodaySpot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [SyncStatusIcon.of(context), 
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingProgressAnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _RecommendedPacks(
            packs: [
              for (final p in context
                  .read<TrainingPackStorageService>()
                  .packs
                  .where((p) => p.isBuiltIn))
                p
            ],
          ),
          const QuickContinueCard(),
          const SpotOfTheDayCard(),
          const ProgressSummaryBox(),
          const StreakChart(),
          const DailyProgressRing(),
          const WeeklyChallengeCard(),
          const XPProgressBar(),
          const RepeatMistakesCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTrainingTemplates(context),
        child: const Icon(Icons.auto_awesome_motion),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse('https://www.youtube.com/watch?v=6H8YJYyK3n8'),
          ),
          icon: const Icon(Icons.music_note),
          label: const Text('Play Chill Mix'),
        ),
      ),
    );
  }
}

class _RecommendedPacks extends StatelessWidget {
  final List<TrainingPack> packs;
  const _RecommendedPacks({required this.packs});

  @override
  Widget build(BuildContext context) {
    if (packs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Рекомендуем для старта',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        for (final p in packs.take(3)) _PackCard(pack: p),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  final TrainingPack pack;
  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.backpack, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.name,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(pack.category,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _startPack(context, pack),
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}

Future<void> _startPack(BuildContext context, TrainingPack pack) async {
  final template = TrainingPackTemplate(
    id: pack.id,
    name: pack.name,
    description: pack.description,
    gameType: pack.gameType,
    spots: [
      for (final h in pack.hands)
        _spotFromHand(h),
    ],
    isBuiltIn: true,
  );
  await context.read<TrainingSessionService>().startSession(template);
  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }
}

TrainingPackSpot _spotFromHand(SavedHand h) {
  return _spotFromTrainingSpot(TrainingSpot.fromSavedHand(h));
}

TrainingPackSpot _spotFromTrainingSpot(TrainingSpot spot) {
  final heroCards = spot.heroIndex < spot.playerCards.length
      ? spot.playerCards[spot.heroIndex]
      : <CardModel>[];
  final hero = heroCards.map((c) => '${c.rank}${c.suit}').join(' ');
  final board = [for (final c in spot.boardCards) '${c.rank}${c.suit}'];
  final actions = <int, List<ActionEntry>>{};
  for (final a in spot.actions) {
    actions.putIfAbsent(a.street, () => []).add(ActionEntry(
      a.street,
      a.playerIndex,
      a.action,
      amount: a.amount?.toDouble(),
      generated: a.generated,
      manualEvaluation: a.manualEvaluation,
      customLabel: a.customLabel,
    ));
  }
  final stacks = <String, double>{};
  for (var i = 0; i < spot.stacks.length; i++) {
    stacks['$i'] = spot.stacks[i].toDouble();
  }
  final pos = spot.heroIndex < spot.positions.length
      ? parseHeroPosition(spot.positions[spot.heroIndex])
      : HeroPosition.unknown;
  return TrainingPackSpot(
    id: const Uuid().v4(),
    hand: HandData(
      heroCards: hero,
      position: pos,
      heroIndex: spot.heroIndex,
      playerCount: spot.numberOfPlayers,
      board: board,
      actions: actions,
      stacks: stacks,
      anteBb: spot.anteBb,
    ),
    tags: List<String>.from(spot.tags),
  );
}
