import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import 'training_session_screen.dart';
import '../theme/app_colors.dart';

class PackSuggestionPreviewScreen extends StatelessWidget {
  final List<TrainingPackTemplateV2> packs;
  const PackSuggestionPreviewScreen({super.key, required this.packs});

  Future<void> _start(BuildContext context, TrainingPackTemplateV2 tpl) async {
    final pack = TrainingPackV2.fromTemplate(tpl, tpl.id);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingSessionScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации')),
      backgroundColor: AppColors.background,
      body: packs.isEmpty
          ? const Center(child: Text('Нет подходящих рекомендаций'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: packs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = packs[index];
                final ev = (p.meta['evScore'] as num?)?.toDouble();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 16)),
                      if (p.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            p.tags.join(', '),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      if (p.audience != null && p.audience!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Audience: ${p.audience!}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      if (ev != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'EV: ${ev.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      if (p.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            p.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _start(context, p),
                          child: const Text('Начать'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
