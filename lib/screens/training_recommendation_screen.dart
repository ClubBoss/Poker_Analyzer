import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../services/goals_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/smart_suggestion_service.dart';
import '../theme/app_colors.dart';
import '../widgets/difficulty_chip.dart';
import '../widgets/progress_chip.dart';
import '../widgets/new_chip.dart';
import 'training_pack_screen.dart';

class TrainingRecommendationScreen extends StatefulWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  State<TrainingRecommendationScreen> createState() => _TrainingRecommendationScreenState();
}

class _TrainingRecommendationScreenState extends State<TrainingRecommendationScreen> {
  Map<String, List<TrainingPack>> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final service = context.read<SmartSuggestionService>();
    final goals = context.read<GoalsService>();
    final mistakes = context.read<MistakeReviewPackService>();
    setState(() {
      _data = service.getExtendedSuggestions(goals, mistakes);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = {
      'almost': 'Почти завершены',
      'stale': 'Давно не открывали',
      'goal': 'По вашей цели',
      'mistakes': 'Ошибки в похожих',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.values.every((e) => e.isEmpty)
              ? const Center(child: Text('Нет рекомендаций'))
              : ListView(
                  children: [
                    for (final key in sections.keys)
                      if (_data[key]?.isNotEmpty ?? false)
                        _Section(
                          title: sections[key]!,
                          packs: _data[key]!,
                        ),
                  ],
                ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<TrainingPack> packs;
  const _Section({required this.title, required this.packs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: packs.length,
              itemBuilder: (_, i) => _PackCard(pack: packs[i]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final TrainingPack pack;
  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    final pct = pack.pctComplete;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: pack)),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(pack.name, style: const TextStyle(color: Colors.white))),
                if (DateTime.now().difference(pack.createdAt).inDays < 7)
                  const SizedBox(width: 4),
                if (DateTime.now().difference(pack.createdAt).inDays < 7)
                  const NewChip(),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                DifficultyChip(pack.difficulty),
                const SizedBox(width: 4),
                ProgressChip(pct),
              ],
            )
          ],
        ),
      ),
    );
  }
}
