import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_preferences_service.dart';

class TutorialCompletionScreen extends StatefulWidget {
  final void Function() onRepeat;

  const TutorialCompletionScreen({super.key, required this.onRepeat});

  @override
  State<TutorialCompletionScreen> createState() => _TutorialCompletionScreenState();
}

class _TutorialCompletionScreenState extends State<TutorialCompletionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserPreferencesService>().setTutorialCompleted(true);
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
              'Обучение завершено',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onRepeat,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
