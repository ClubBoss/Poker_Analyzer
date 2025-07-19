import 'package:flutter/material.dart';

import '../models/v3/lesson_step.dart';

class LessonStepScreen extends StatelessWidget {
  final LessonStep step;
  const LessonStepScreen({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(step.title)),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          step.introText,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
