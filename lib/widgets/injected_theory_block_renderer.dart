import 'package:flutter/material.dart';

import '../models/learning_path_block.dart';
import '../models/theory_block_model.dart';
import '../widgets/theory_block_card_widget.dart';
import '../services/theory_path_completion_evaluator_service.dart';
import '../services/user_progress_service.dart';

/// Renders an injected theory [LearningPathBlock] using [TheoryBlockCardWidget].
class InjectedTheoryBlockRenderer extends StatefulWidget {
  final LearningPathBlock block;
  const InjectedTheoryBlockRenderer({super.key, required this.block});

  @override
  State<InjectedTheoryBlockRenderer> createState() =>
      _InjectedTheoryBlockRendererState();
}

class _InjectedTheoryBlockRendererState
    extends State<InjectedTheoryBlockRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = TheoryBlockModel(
      id: widget.block.id,
      title: widget.block.header,
      nodeIds: [widget.block.lessonId],
      practicePackIds: const [],
    );
    final evaluator = TheoryPathCompletionEvaluatorService(
      userProgress: UserProgressService.instance,
    );
    return FadeTransition(
      opacity: _anim,
      child: TheoryBlockCardWidget(
        block: model,
        evaluator: evaluator,
        progress: UserProgressService.instance,
      ),
    );
  }
}
