import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/v2/training_pack_template.dart';
import '../models/action_entry.dart';
import '../helpers/hand_utils.dart';
import '../services/pack_generator_service.dart';
import '../services/training_session_service.dart';
import '../services/smart_suggestion_service.dart';
import '../services/pack_favorite_service.dart';
import 'training_session_screen.dart';

class PackPreviewScreen extends StatefulWidget {
  final TrainingPackTemplate pack;
  const PackPreviewScreen({super.key, required this.pack});

  @override
  State<PackPreviewScreen> createState() => _PackPreviewScreenState();
}

class _PackPreviewScreenState extends State<PackPreviewScreen> {
  final List<TrainingPackTemplate> _related = [];
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.pack.id);
    _loadRelated();
  }

  Future<void> _toggleFavorite() async {
    await PackFavoriteService.instance.toggleFavorite(widget.pack.id);
    if (mounted) setState(() => _favorite = !_favorite);
  }

  Future<void> _loadRelated() async {
    final service = context.read<SmartSuggestionService>();
    final paths = await service.suggestRelated(widget.pack.tags);
    final docs = await getApplicationDocumentsDirectory();
    const reader = YamlReader();
    for (final rel in paths) {
      final file = File(p.join(docs.path, 'training_packs', 'library', rel));
      if (!file.existsSync()) continue;
      try {
        final map = reader.read(await file.readAsString());
        _related.add(TrainingPackTemplate.fromJson(map));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  String _villainRange() {
    final count =
        (PackGeneratorService.handRanking.length * widget.pack.bbCallPct / 100)
            .round();
    return PackGeneratorService.handRanking.take(count).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final villain = _villainRange();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.name),
        actions: [
          IconButton(
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
            color: _favorite ? Colors.amber : Colors.white,
            onPressed: _toggleFavorite,
          ),
          TextButton(
            onPressed: () async {
              final session = await context
                  .read<TrainingSessionService>()
                  .startFromTemplate(widget.pack);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingSessionScreen(session: session),
                ),
              );
            },
            child: const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (var i = 0; i < widget.pack.spots.length; i++)
            _buildSpot(i, villain),
          if (_related.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '🎯 Похожее по теме',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            for (final r in _related)
              ListTile(
                title: Text(r.name),
                onTap: () async {
                  final session = await context
                      .read<TrainingSessionService>()
                      .startFromTemplate(r);
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingSessionScreen(session: session),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpot(int index, String villain) {
    final s = widget.pack.spots[index];
    final hero = handCode(s.hand.heroCards) ?? s.hand.heroCards;
    final actions = s.hand.actions[0] ?? [];
    ActionEntry? heroAct;
    for (final a in actions) {
      if (a.playerIndex == s.hand.heroIndex) {
        heroAct = a;
        break;
      }
    }
    final act = heroAct?.customLabel ?? heroAct?.action;
    return ListTile(
      leading: Text('${index + 1}'),
      title: Text(s.title.isEmpty ? 'Spot ${index + 1}' : s.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hero: $hero'),
          Text('Villain: $villain'),
          if (act != null) Text('Action: $act'),
        ],
      ),
    );
  }
}
