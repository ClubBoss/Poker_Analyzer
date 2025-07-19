import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/confetti_overlay.dart';
import '../services/learning_path_progress_service.dart';
import 'learning_path_screen.dart';

class LearningPathCompletionScreen extends StatefulWidget {
  const LearningPathCompletionScreen({super.key});

  @override
  State<LearningPathCompletionScreen> createState() => _LearningPathCompletionScreenState();
}

class _LearningPathCompletionScreenState extends State<LearningPathCompletionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  Future<void> _reset() async {
    await LearningPathProgressService.instance.resetProgress();
    await LearningPathProgressService.instance.resetIntroSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LearningPathScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎓 Вы завершили весь путь обучения!',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (kDebugMode)
              ElevatedButton(
                onPressed: _reset,
                child: const Text('Вернуться к началу'),
              ),
          ],
        ),
      ),
    );
  }
}
