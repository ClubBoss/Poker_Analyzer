import 'package:flutter/material.dart';
import '../models/skill_tree_node_model.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../widgets/tag_badge.dart';
import '../widgets/training_spot_preview.dart';

class SkillTreeNodeDetailView extends StatefulWidget {
  final SkillTreeNodeModel node;
  final bool unlocked;
  const SkillTreeNodeDetailView(
      {super.key, required this.node, this.unlocked = true});

  @override
  State<SkillTreeNodeDetailView> createState() =>
      _SkillTreeNodeDetailViewState();
}

class _SkillTreeNodeDetailViewState extends State<SkillTreeNodeDetailView> {
  TheoryMiniLessonNode? _lesson;
  TrainingPackTemplateV2? _template;
  TrainingSpot? _previewSpot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.node.theoryLessonId.isNotEmpty) {
      await MiniLessonLibraryService.instance.loadAll();
      _lesson =
          MiniLessonLibraryService.instance.getById(widget.node.theoryLessonId);
    }
    if (widget.node.trainingPackId.isNotEmpty) {
      _template =
          await PackLibraryService.instance.getById(widget.node.trainingPackId);
      if (_template != null && _template!.spots.isNotEmpty) {
        _previewSpot = _convertSpot(_template!.spots.first);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  TrainingSpot _convertSpot(TrainingPackSpot spot) {
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[]
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1))
    ];
    final actions = hand.actions.values.expand((l) => l).toList();
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++) hand.stacks['$i']?.round() ?? 0
    ];
    final positions = List.generate(hand.playerCount, (_) => '');
    if (hand.heroIndex < positions.length) {
      positions[hand.heroIndex] = hand.position.label;
    }
    return TrainingSpot(
      playerCards: playerCards,
      boardCards: boardCards,
      actions: actions,
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.playerCount,
      playerTypes: List.generate(hand.playerCount, (_) => PlayerType.unknown),
      positions: positions,
      stacks: stacks,
      tags: List<String>.from(spot.tags),
      recommendedAction: spot.correctAction,
      difficulty: 3,
      rating: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _startDrill() async {
    final tpl = _template;
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  String _shortDescription(String text, {int max = 160}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: Text(widget.node.title)),
      backgroundColor: const Color(0xFF121212),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_lesson != null) ...[
                      Text(
                        _lesson!.resolvedTitle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_lesson!.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: -4,
                            children: [
                              for (final t in _lesson!.tags.take(3)) TagBadge(t)
                            ],
                          ),
                        ),
                      if (_lesson!.resolvedContent.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _shortDescription(_lesson!.resolvedContent),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                    if (_previewSpot != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Example Spot',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TrainingSpotPreview(spot: _previewSpot!),
                    ],
                    if (_template != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.unlocked ? _startDrill : null,
                          style:
                              ElevatedButton.styleFrom(backgroundColor: accent),
                          child: const Text('Start Drill'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!widget.unlocked)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.lock, size: 64, color: Colors.white38),
                  ),
              ],
            ),
    );
  }
}
