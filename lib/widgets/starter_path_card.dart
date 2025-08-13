import 'package:flutter/material.dart';

import '../services/learning_path_service.dart';
import '../screens/v2/training_pack_play_screen.dart';
import '../models/v2/training_pack_template_v2.dart';

class StarterPathCard extends StatefulWidget {
  const StarterPathCard({super.key});

  @override
  State<StarterPathCard> createState() => _StarterPathCardState();
}

class _StarterPathCardState extends State<StarterPathCard> {
  late Future<void> _future;
  List<TrainingPackTemplateV2>? _packs;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    _packs = LearningPathService.instance.buildStarterPath();
    _progress = await LearningPathService.instance.getStarterPathProgress();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (_packs == null) return const SizedBox.shrink();
        final completed = _progress >= _packs!.length;
        if (completed) {
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
                  '🎯 Starter Path',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Путь завершен!',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () async {
                      await LearningPathService.instance.resetStarterPath();
                      setState(() => _future = _load());
                    },
                    child: const Text('Сбросить'),
                  ),
                ),
              ],
            ),
          );
        }
        final tpl = _packs![_progress];
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
                '🎯 Starter Path',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Шаг ${_progress + 1}/${_packs!.length}: ${tpl.name}',
                style: const TextStyle(color: Colors.white),
              ),
              if (tpl.description.isNotEmpty)
                Text(tpl.description,
                    style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackPlayScreen(
                            template: tpl, original: tpl),
                      ),
                    ).then((_) => setState(() => _future = _load()));
                  },
                  child: const Text('Продолжить путь'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
