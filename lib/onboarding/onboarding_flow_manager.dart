import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pack_library_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import '../theme/app_colors.dart';

abstract class OnboardingStep {
  Future<void> run(BuildContext context, OnboardingFlowManager manager);
}

class OnboardingFlowManager {
  static const _completedKey = 'onboardingCompleted';
  OnboardingFlowManager._();
  static final instance = OnboardingFlowManager._();

  bool _completed = false;
  bool get completed => _completed;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_completedKey) ?? false;
  }

  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    _completed = true;
  }

  Future<bool> _hasCompletedTraining() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys()) {
      if (k.startsWith('completed_tpl_') && prefs.getBool(k) == true) {
        return true;
      }
    }
    return false;
  }

  Future<void> maybeStart(BuildContext context) async {
    await _load();
    if (_completed) return;
    if (await _hasCompletedTraining()) return;
    final steps = [_WelcomeStep(), _PackStep(), _CongratsStep()];
    for (final s in steps) {
      await s.run(context, this);
    }
    await _markCompleted();
  }
}

class _WelcomeStep implements OnboardingStep {
  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _WelcomeScreen()),
    );
  }
}

class _PackStep implements OnboardingStep {
  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    final pack = await PackLibraryService.instance.recommendedStarter();
    if (pack == null) return;
    await context.read<TrainingSessionService>().startSession(pack);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }
}

class _CongratsStep implements OnboardingStep {
  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Поздравляем!'),
        content: const Text('Вы завершили первую тренировку'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Изучай покер через готовые раздачи',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Начать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
