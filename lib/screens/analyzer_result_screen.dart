import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/saved_hand_manager_service.dart';
import 'training_session_screen.dart';
import '../theme/app_colors.dart';

class AnalyzerResultScreen extends StatefulWidget {
  final SavedHand hand;
  const AnalyzerResultScreen({super.key, required this.hand});

  @override
  State<AnalyzerResultScreen> createState() => _AnalyzerResultScreenState();
}

class _AnalyzerResultScreenState extends State<AnalyzerResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loss = widget.hand.evLoss ?? 0;
      if (loss.abs() >= 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('EV Loss ≥ 1.0'),
            action: SnackBarAction(
              label: 'Тренировать похожее',
              onPressed: () async {
                final tpl = await TrainingPackService.createSimilarMistakeDrill(widget.hand);
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
    final exp = widget.hand.expectedAction?.trim().toLowerCase();
    final gto = widget.hand.gtoAction?.trim().toLowerCase();
    if (exp == null || gto == null) return false;
    if ((widget.hand.evLoss ?? 0).abs() < 1.0) return false;
    return exp != gto;
  }

  @override
  Widget build(BuildContext context) {
    final similarCount = context.select<SavedHandManagerService, int>((s) {
      final cat = widget.hand.category;
      final pos = widget.hand.heroPosition;
      final stack = widget.hand.stackSizes[widget.hand.heroIndex];
      if (cat == null || stack == null) return 0;
      return s.hands
          .where((h) =>
              h != widget.hand &&
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
                        await TrainingPackService.createSimilarMistakeDrill(
                            widget.hand);
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
