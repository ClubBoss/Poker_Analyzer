import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template.dart';
import '../services/training_session_service.dart';
import 'training_pack_template_list_screen.dart';
import 'training_session_screen.dart';

class TrainingSessionCompletionScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  final int hands;
  const TrainingSessionCompletionScreen({
    super.key,
    required this.template,
    required this.hands,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = template.spots.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Тренировка завершена')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Вы завершили тренировку!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('$hands / $total пройдено'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<TrainingSessionService>()
                    .startSession(template, persist: false, startIndex: 0);
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrainingSessionScreen(),
                  ),
                );
              },
              child: const Text('Повторить'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrainingPackTemplateListScreen(),
                  ),
                );
              },
              child: const Text('Выбрать другой пак'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Домой'),
            ),
          ],
        ),
      ),
    );
  }
}
