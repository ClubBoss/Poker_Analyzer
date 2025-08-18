import 'package:flutter/material.dart';
import '../services/learning_suggestion_service.dart';
import '../services/training_pack_template_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

class LearningPathRecommendationBanner extends StatefulWidget {
  const LearningPathRecommendationBanner({super.key});

  @override
  State<LearningPathRecommendationBanner> createState() =>
      _LearningPathRecommendationBannerState();
}

class _LearningPathRecommendationBannerState
    extends State<LearningPathRecommendationBanner> {
  late Future<LearningPackSuggestion?> _future;

  @override
  void initState() {
    super.initState();
    _future = const LearningSuggestionService().nextSuggestedPack(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<LearningPackSuggestion?>(
      future: _future,
      builder: (context, snapshot) {
        final suggestion = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            suggestion == null) {
          return const SizedBox.shrink();
        }
        final tpl = TrainingPackTemplateService.getById(
          suggestion.templateId,
          context,
        );
        if (tpl == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📌 \u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0439\u0442\u0438',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(tpl.name, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                suggestion.suggestionReason,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackPlayScreen(
                          template: tpl,
                          original: tpl,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text(
                    '\u041f\u0435\u0440\u0435\u0439\u0442\u0438',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
