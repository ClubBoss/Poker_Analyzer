import 'package:flutter/material.dart';
import '../models/training_pack_template.dart';
import 'v2/training_pack_play_screen.dart';

class MistakeReviewScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  const MistakeReviewScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return TrainingPackPlayScreen(template: template, original: template);
  }
}
