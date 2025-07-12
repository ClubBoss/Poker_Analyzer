import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Результаты анализа')),
      backgroundColor: AppColors.background,
      body: const SizedBox.shrink(),
      floatingActionButton: _isMistake
          ? FloatingActionButton.extended(
              onPressed: () async {
                final tpl = await TrainingPackService.createDrillFromSimilarHands(
                    context, hand);
                if (tpl == null) return;
                await context.read<TrainingSessionService>().startSession(tpl);
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
            )
          : null,
    );
  }
}
