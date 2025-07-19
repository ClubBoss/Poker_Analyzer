import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/learning_path_progress_service.dart';
import 'learning_path_screen.dart';

class LearningPathIntroScreen extends StatelessWidget {
  const LearningPathIntroScreen({super.key});

  Future<void> _start(BuildContext context) async {
    await LearningPathProgressService.instance.markIntroSeen();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LearningPathScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/learning_intro.svg',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 24),
              const Text(
                '🎯 Добро пожаловать в путь обучения',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Освой ключевые споты, прокачай навыки, открой продвинутые режимы',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _start(context),
                child: const Text('Начать обучение'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await LearningPathProgressService.instance.resetIntroSeen();
                  },
                  child: const Text('Сбросить флаг'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
