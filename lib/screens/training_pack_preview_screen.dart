import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../services/pack_favorite_service.dart';
import 'training_session_screen.dart';

class TrainingPackPreviewScreen extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  const TrainingPackPreviewScreen({super.key, required this.template});

  @override
  State<TrainingPackPreviewScreen> createState() =>
      _TrainingPackPreviewScreenState();
}

class _TrainingPackPreviewScreenState extends State<TrainingPackPreviewScreen> {
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.template.id);
  }

  Future<void> _toggleFavorite() async {
    await PackFavoriteService.instance.toggleFavorite(widget.template.id);
    if (mounted) setState(() => _favorite = !_favorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
            color: _favorite ? Colors.amber : Colors.white,
            onPressed: _toggleFavorite,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.template.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Type: ${widget.template.trainingType.name}',
              style: const TextStyle(color: Colors.white70)),
          if (widget.template.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tags: ${widget.template.tags.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.audience != null &&
              widget.template.audience!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Audience: ${widget.template.audience!}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.template.description,
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.goal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Goal: ${widget.template.goal}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Positions: ${widget.template.positions.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Meta:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final e in widget.template.meta.entries)
              Text('${e.key}: ${e.value}',
                  style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.spotCount > 0) ...[
            const SizedBox(height: 8),
            Text('Spots: ${widget.template.spotCount}',
                style: const TextStyle(color: Colors.white70)),
          ],
          if (widget.template.spots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Примеры:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final s in widget.template.spots.take(3))
              ListTile(
                title: Text(s.title.isEmpty ? 'Spot' : s.title),
                subtitle: Text('Tags: ${s.tags.join(', ')}'),
              ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final pack = TrainingPackV2.fromTemplate(
                  widget.template, widget.template.id);
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
