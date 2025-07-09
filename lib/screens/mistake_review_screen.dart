import 'package:flutter/material.dart';
import '../services/mistake_review_pack_service.dart';
import 'v2/training_pack_play_screen.dart';

class MistakeReviewScreen extends StatelessWidget {
  const MistakeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tpl = MistakeReviewPackService.cachedTemplate;
    if (tpl == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return TrainingPackPlayScreen(template: tpl, original: tpl);
  }
}
