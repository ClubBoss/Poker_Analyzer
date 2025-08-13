import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/saved_hand.dart';
import '../models/training_attempt.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_session_service.dart';
import '../services/weakness_cluster_engine_v2.dart';
import 'training_session_screen.dart';

class WeaknessOverviewScreen extends StatefulWidget {
  static const route = '/weakness_overview';
  const WeaknessOverviewScreen({super.key});

  @override
  State<WeaknessOverviewScreen> createState() => _WeaknessOverviewScreenState();
}

class _WeaknessOverviewScreenState extends State<WeaknessOverviewScreen> {
  late Future<List<WeaknessCluster>> _future;
  late Map<String, SavedHand> _handById;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  String _handId(SavedHand h) =>
      h.spotId ?? h.savedAt.millisecondsSinceEpoch.toString();

  TrainingPackSpot _spotFromHand(SavedHand h) {
    final hero =
        h.playerCards[h.heroIndex].map((c) => '${c.rank}${c.suit}').join(' ');
    final board = [for (final c in h.boardCards) '${c.rank}${c.suit}'];
    final actions = <int, List<ActionEntry>>{};
    for (final a in h.actions) {
      actions.putIfAbsent(a.street, () => []).add(ActionEntry(
            a.street,
            a.playerIndex,
            a.action,
            amount: a.amount,
            generated: a.generated,
            manualEvaluation: a.manualEvaluation,
            customLabel: a.customLabel,
          ));
    }
    final stacks = <String, double>{
      for (final e in h.stackSizes.entries) '${e.key}': e.value.toDouble()
    };
    final tags = List<String>.from(h.tags);
    if (h.category != null && h.category!.isNotEmpty)
      tags.add('cat:${h.category}');
    return TrainingPackSpot(
      id: _handId(h),
      title: h.name,
      hand: HandData(
        heroCards: hero,
        position: parseHeroPosition(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        board: board,
        actions: actions,
        stacks: stacks,
        anteBb: h.anteBb,
      ),
      tags: tags,
    );
  }

  Future<List<WeaknessCluster>> _load() async {
    final manager = context.read<SavedHandManagerService>();
    final hands = manager.hands;
    _handById = {for (final h in hands) _handId(h): h};

    final spots = <TrainingPackSpot>[];
    final attempts = <TrainingAttempt>[];

    for (final h in hands) {
      spots.add(_spotFromHand(h));
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (exp == null || gto == null) continue;
      final acc =
          exp.trim().toLowerCase() == gto.trim().toLowerCase() ? 1.0 : 0.0;
      attempts.add(TrainingAttempt(
        packId: 'history',
        spotId: _handId(h),
        timestamp: h.savedAt,
        accuracy: acc,
        ev: 0,
        icm: 0,
      ));
    }

    if (attempts.isEmpty) return [];

    final pack = TrainingPackTemplateV2(
      id: 'history',
      name: 'History',
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );

    const engine = WeaknessClusterEngine();
    final clusters =
        engine.computeClusters(attempts: attempts, allPacks: [pack]);
    return clusters.take(5).toList();
  }

  Future<void> _startTraining(WeaknessCluster c) async {
    final hands = [
      for (final id in c.spotIds)
        if (_handById[id] != null) _handById[id]!
    ];
    if (hands.isEmpty) return;
    final spots = [for (final h in hands) _spotFromHand(h)];
    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Drill: ${c.label}',
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );
    await context.read<TrainingSessionService>().startSession(tpl);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  Widget _clusterTile(WeaknessCluster c) {
    final samples = [for (final id in c.spotIds.take(2)) _handById[id]]
        .whereType<SavedHand>()
        .toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
                'Avg Accuracy: ${(c.avgAccuracy * 100).toStringAsFixed(0)}% · ${c.spotIds.length} spots'),
            const SizedBox(height: 8),
            for (final h in samples)
              Text(
                  '${h.heroPosition} – ${h.boardCards.map((c) => '${c.rank}${c.suit}').join(' ')}'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _startTraining(c),
                child: const Text('Train This'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weaknesses')),
      body: FutureBuilder<List<WeaknessCluster>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clusters = snapshot.data!;
          if (clusters.isEmpty) {
            return const Center(child: Text('No weaknesses detected'));
          }
          return ListView(
            children: [for (final c in clusters) _clusterTile(c)],
          );
        },
      ),
    );
  }
}
