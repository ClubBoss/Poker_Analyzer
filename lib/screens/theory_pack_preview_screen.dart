import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';

/// Displays a lightweight preview of theory spots before starting a session.
class TheoryPackPreviewScreen extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  const TheoryPackPreviewScreen({super.key, required this.template});

  void _start(BuildContext context) {
    final pack = TrainingPackV2.fromTemplate(template, template.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrainingSessionScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: template.spots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final spot = template.spots[i];
          final subtitle = spot.explanation?.split('\n').first ?? '';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.title.isNotEmpty ? spot.title : 'Spot ${i + 1}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _start(context),
            child: const Text('Начать изучение'),
          ),
        ),
      ),
    );
  }
}
