import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import 'training_session_screen.dart';

class TrainingPackPreviewScreen extends StatelessWidget {
  final TrainingPackTemplateV2 template;
  const TrainingPackPreviewScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(template.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Type: ${template.trainingType.name}', style: const TextStyle(color: Colors.white70)),
          if (template.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tags: ${template.tags.join(', ')}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.audience != null && template.audience!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Audience: ${template.audience!}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(template.description, style: const TextStyle(color: Colors.white70)),
          ],
          if (template.goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Goal: ${template.goal}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Positions: ${template.positions.join(', ')}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Meta:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in template.meta.entries)
              Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.spotCount > 0) ...[
            const SizedBox(height: 8),
            Text('Spots: ${template.spotCount}', style: const TextStyle(color: Colors.white70)),
          ],
          if (template.spots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Примеры:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final s in template.spots.take(3))
              ListTile(
                title: Text(s.title.isEmpty ? 'Spot' : s.title),
                subtitle: Text('Tags: ${s.tags.join(', ')}'),
              ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final pack = TrainingPackV2.fromTemplate(template, template.id);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingSessionScreen(pack: pack),
                ),
              );
            },
            child: const Text('Начать тренировку'),
          ),
        ],
      ),
    );
  }
}

