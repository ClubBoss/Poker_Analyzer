import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_session_screen.dart';
import '../theme/app_colors.dart';

class AnalyzerResultScreen extends StatelessWidget {
  final SavedHand hand;
  const AnalyzerResultScreen({super.key, required this.hand});

  bool get _isMistake {
    final exp = hand.expectedAction?.trim().toLowerCase();
    final gto = hand.gtoAction?.trim().toLowerCase();
    if (exp == null || gto == null) return false;
    return exp != gto;
  }

  @override
  Widget build(BuildContext context) {
    final similarCount = context.select<SavedHandManagerService, int>((s) {
      final cat = hand.category;
      final pos = hand.heroPosition;
      final stack = hand.stackSizes[hand.heroIndex];
      if (cat == null || stack == null) return 0;
      return s.hands
          .where((h) =>
              h != hand &&
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
      appBar: AppBar(title: const Text('Результаты анализа')),
      backgroundColor: AppColors.background,
      body: const SizedBox.shrink(),
      floatingActionButton: showFab
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: () async {
                    final tpl =
                        await TrainingPackService.createDrillFromSimilarHands(
                            context, hand);
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
