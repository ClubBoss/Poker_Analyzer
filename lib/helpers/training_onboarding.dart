import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/ready_to_train_screen.dart';
import '../screens/training_onboarding_screen.dart';

Future<void> openTrainingTemplates(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('seen_training_onboarding') ?? false;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          seen ? const ReadyToTrainScreen() : const TrainingOnboardingScreen(),
    ),
  );
}
