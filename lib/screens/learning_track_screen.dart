import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../models/theory_track_model.dart';
import '../services/theory_track_progression_service.dart';
import '../services/theory_path_completion_evaluator_service.dart';
import '../services/user_progress_service.dart';
import '../widgets/theory_block_card_widget.dart';

/// Displays blocks of a [TheoryTrackModel] respecting progression rules.
class LearningTrackScreen extends StatefulWidget {
  final TheoryTrackModel track;
  const LearningTrackScreen({super.key, required this.track});

  @override
  State<LearningTrackScreen> createState() => _LearningTrackScreenState();
}

class _LearningTrackScreenState extends State<LearningTrackScreen> {
  late final TheoryPathCompletionEvaluatorService _evaluator;
  late final TheoryTrackProgressionService _progression;
  List<TheoryBlockModel>? _unlocked;

  @override
  void initState() {
    super.initState();
    _evaluator = TheoryPathCompletionEvaluatorService(
      userProgress: UserProgressService.instance,
    );
    _progression = TheoryTrackProgressionService(evaluator: _evaluator);
    _load();
  }

  Future<void> _load() async {
    final unlocked = await _progression.getUnlockedBlocks(widget.track);
    if (mounted) {
      setState(() => _unlocked = unlocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    return Scaffold(
      appBar: AppBar(title: Text(widget.track.title)),
      backgroundColor: const Color(0xFF121212),
      body: unlocked == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: widget.track.blocks.length,
              itemBuilder: (context, index) {
                final block = widget.track.blocks[index];
                final isUnlocked =
                    unlocked.any((b) => b.id == block.id);
                final card = TheoryBlockCardWidget(
                  block: block,
                  evaluator: _evaluator,
                  progress: UserProgressService.instance,
                );
                return isUnlocked
                    ? card
                    : Opacity(
                        opacity: 0.5,
                        child: IgnorePointer(child: card),
                      );
              },
            ),
    );
  }
}
