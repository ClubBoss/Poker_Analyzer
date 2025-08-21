import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../models/theory_track_model.dart';
import '../services/theory_track_progression_service.dart';
import '../services/theory_path_completion_evaluator_service.dart';
import '../services/user_progress_service.dart';
import '../services/theory_track_resume_service.dart';
import '../widgets/theory_block_card_widget.dart';

/// Displays blocks of a [TheoryTrackModel] respecting progression rules.
class LearningTrackScreen extends StatefulWidget {
  final TheoryTrackModel track;
  final String? initialBlockId;
  const LearningTrackScreen({
    super.key,
    required this.track,
    this.initialBlockId,
  });

  @override
  State<LearningTrackScreen> createState() => _LearningTrackScreenState();
}

class _LearningTrackScreenState extends State<LearningTrackScreen> {
  late final TheoryPathCompletionEvaluatorService _evaluator;
  late final TheoryTrackProgressionService _progression;
  final Map<String, GlobalKey> _blockKeys = {};
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
    final last = widget.initialBlockId ??
        await TheoryTrackResumeService.instance.getLastVisitedBlock(
          widget.track.id,
        );
    if (mounted) {
      setState(() => _unlocked = unlocked);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetId = (last != null && unlocked.any((b) => b.id == last))
            ? last
            : unlocked.isNotEmpty
                ? unlocked.first.id
                : null;
        final key = targetId != null ? _blockKeys[targetId] : null;
        final context = key?.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
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
                final key = _blockKeys.putIfAbsent(block.id, () => GlobalKey());
                final isUnlocked = unlocked.any((b) => b.id == block.id);
                final card = TheoryBlockCardWidget(
                  key: key,
                  block: block,
                  evaluator: _evaluator,
                  progress: UserProgressService.instance,
                  trackId: widget.track.id,
                );
                return isUnlocked
                    ? card
                    : Opacity(opacity: 0.5, child: IgnorePointer(child: card));
              },
            ),
    );
  }
}
