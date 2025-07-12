import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_session_screen.dart';
import '../theme/app_colors.dart';
import '../screens/saved_hand_editor_screen.dart';
import '../services/evaluation_executor_service.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/action_entry.dart';
import 'package:uuid/uuid.dart';

class AnalyzerResultScreen extends StatefulWidget {
  final SavedHand hand;
  const AnalyzerResultScreen({super.key, required this.hand});

  @override
  State<AnalyzerResultScreen> createState() => _AnalyzerResultScreenState();
}

class _AnalyzerResultScreenState extends State<AnalyzerResultScreen> {
  late SavedHand _hand;

  Future<void> _edit() async {
    final result = await Navigator.push<SavedHand>(
      context,
      MaterialPageRoute(builder: (_) => SavedHandEditorScreen(hand: _hand)),
    );
    if (result != null && mounted) {
      _hand = result;
      setState(() {});
      await _evaluate();
    }
  }

  TrainingPackSpot _spotFromHand(SavedHand h) {
    final hero = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <int, List<ActionEntry>>{for (var s = 0; s < 4; s++) s: []};
    for (final a in h.actions) {
      actions[a.street]!.add(a);
    }
    final stacks = <String, double>{
      for (int i = 0; i < h.numberOfPlayers; i++)
        '$i': (h.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: hero,
        position: parseHeroPosition(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        stacks: stacks,
        board: [for (final c in h.boardCards) '${c.rank}${c.suit}'],
        actions: actions,
        anteBb: h.anteBb,
      ),
    );
  }

  Future<void> _evaluate() async {
    final spot = _spotFromHand(_hand);
    await context
        .read<EvaluationExecutorService>()
        .evaluateSingle(context, spot, hand: _hand, anteBb: _hand.anteBb);
    final acts = <ActionEntry>[];
    for (final l in spot.hand.actions.values) {
      acts.addAll(l);
    }
    final updated = _hand.copyWith(
      actions: acts,
      gtoAction: spot.correctAction,
    );
    await context.read<SavedHandManagerService>().save(updated);
    if (mounted) setState(() => _hand = updated);
  }

  @override
  void initState() {
    super.initState();
    _hand = widget.hand;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loss = _hand.evLoss ?? 0;
      if (loss.abs() >= 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('EV Loss ≥ 1.0'),
            action: SnackBarAction(
              label: 'Тренировать похожее',
              onPressed: () async {
                final tpl = await TrainingPackService.createSimilarMistakeDrill(_hand);
                if (tpl == null) return;
                await context.read<TrainingSessionService>().startSession(tpl);
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                  );
                }
              },
            ),
          ),
        );
      }
    });
  }

  bool get _isMistake {
    final exp = _hand.expectedAction?.trim().toLowerCase();
    final gto = _hand.gtoAction?.trim().toLowerCase();
    if (exp == null || gto == null) return false;
    if ((_hand.evLoss ?? 0).abs() < 1.0) return false;
    return exp != gto;
  }

  @override
  Widget build(BuildContext context) {
    final similarCount = context.select<SavedHandManagerService, int>((s) {
      final cat = _hand.category;
      final pos = _hand.heroPosition;
      final stack = _hand.stackSizes[_hand.heroIndex];
      if (cat == null || stack == null) return 0;
      return s.hands
          .where((h) =>
              h != _hand &&
              h.category == cat &&
              h.heroPosition == pos &&
              h.stackSizes[h.heroIndex] == stack &&
              h.expectedAction != null &&
              h.gtoAction != null &&
              h.expectedAction!.trim().toLowerCase() !=
                  h.gtoAction!.trim().toLowerCase())
          .length;
    });
    final showFab = _isMistake && similarCount > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты анализа'),
        actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.edit))],
      ),
      backgroundColor: AppColors.background,
      body: const SizedBox.shrink(),
      floatingActionButton: showFab
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: () async {
                    final tpl =
                        await TrainingPackService.createSimilarMistakeDrill(
                            _hand);
                    if (tpl == null) return;
                    await context
                        .read<TrainingSessionService>()
                        .startSession(tpl);
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrainingSessionScreen()),
                      );
                    }
                  },
                  label: const Text('Отработать похожие'),
                  icon: const Icon(Icons.fitness_center),
                ),
                const SizedBox(height: 8),
                Text('$similarCount похожих ошибок',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70)),
              ],
            )
          : null,
    );
  }
}
