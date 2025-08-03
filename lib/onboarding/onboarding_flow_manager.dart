import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:provider/provider.dart';

import '../services/pack_library_service.dart';
import '../services/training_session_service.dart';
import '../services/smart_review_service.dart';
import '../services/template_storage_service.dart';
import '../screens/training_session_screen.dart';
import '../screens/mistake_review_screen.dart';
import '../theme/app_colors.dart';

abstract class OnboardingStep {
  Future<void> run(BuildContext context, OnboardingFlowManager manager);
}

class OnboardingFlowManager {
  static const _completedKey = 'onboardingCompleted';
  static const _mistakeRepeatKey = 'mistakeRepeatCompleted';
  OnboardingFlowManager._();
  static final instance = OnboardingFlowManager._();

  bool _completed = false;
  bool _mistakeRepeatCompleted = false;
  bool get completed => _completed;

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    _completed = prefs.getBool(_completedKey) ?? false;
    _mistakeRepeatCompleted = prefs.getBool(_mistakeRepeatKey) ?? false;
  }

  Future<void> _markCompleted() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_completedKey, true);
    _completed = true;
  }

  Future<void> _markMistakeRepeatCompleted() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_mistakeRepeatKey, true);
    _mistakeRepeatCompleted = true;
  }

  Future<bool> _hasCompletedTraining() async {
    final prefs = await PreferencesService.getInstance();
    for (final k in prefs.getKeys()) {
      if (k.startsWith('completed_tpl_') && prefs.getBool(k) == true) {
        return true;
      }
    }
    return false;
  }

  Future<void> maybeStart(BuildContext context) async {
    await _load();
    if (!_completed) {
      if (await _hasCompletedTraining()) return;
      final steps = [_WelcomeStep(), _PackStep()];
      for (final s in steps) {
        await s.run(context, this);
      }
      final hasMistakes = SmartReviewService.instance.hasMistakes();
      await _CongratsStep(showRepeat: hasMistakes).run(context, this);
      if (hasMistakes && !_mistakeRepeatCompleted) {
        await _MistakeRepeatStep().run(context, this);
        await _MistakeRepeatCongratsStep().run(context, this);
        await _markMistakeRepeatCompleted();
      }
      await _markCompleted();
    } else if (!_mistakeRepeatCompleted &&
        SmartReviewService.instance.hasMistakes()) {
      await _MistakeRepeatStep().run(context, this);
      await _MistakeRepeatCongratsStep().run(context, this);
      await _markMistakeRepeatCompleted();
    }
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
  final bool showRepeat;
  const _CongratsStep({required this.showRepeat});

  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Поздравляем!'),
        content: Text(showRepeat
            ? 'Вы завершили первую тренировку. Хотите закрепить материал?'
            : 'Вы завершили первую тренировку'),
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

class _MistakeRepeatStep implements OnboardingStep {
  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    final templates = context.read<TemplateStorageService>();
    final spots = await SmartReviewService.instance
        .getMistakeSpots(templates, context: context);
    if (spots.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MistakeReviewScreen()),
    );
  }
}

class _MistakeRepeatCongratsStep implements OnboardingStep {
  @override
  Future<void> run(BuildContext context, OnboardingFlowManager manager) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎯 Отлично! Ошибки проработаны'),
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
  const _WelcomeScreen();

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
