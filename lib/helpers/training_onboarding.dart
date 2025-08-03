import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../screens/ready_to_train_screen.dart';
import '../screens/training_onboarding_screen.dart';

Future<void> openTrainingTemplates(BuildContext context) async {
  final prefs = await PreferencesService.getInstance();
  final seen = prefs.getBool('seen_training_onboarding') ?? false;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => seen
          ? const ReadyToTrainScreen()
          : const TrainingOnboardingScreen(),
    ),
  );
}
