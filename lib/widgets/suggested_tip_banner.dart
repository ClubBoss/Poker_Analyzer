import 'package:flutter/material.dart';

import '../services/learning_suggestion_service.dart';
import '../services/training_pack_template_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

class SuggestedTipBanner extends StatefulWidget {
  const SuggestedTipBanner({super.key});

  @override
  State<SuggestedTipBanner> createState() => _SuggestedTipBannerState();
}

class _SuggestedTipBannerState extends State<SuggestedTipBanner>
    with SingleTickerProviderStateMixin {
  LearningTip? _tip;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _load();
  }

  Future<void> _load() async {
    final tip = await const LearningSuggestionService().getTip();
    if (mounted) {
      setState(() => _tip = tip);
      if (tip != null) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onAction() async {
    final tip = _tip;
    if (tip == null) return;
    switch (tip.action) {
      case LearningTipAction.continuePack:
      case LearningTipAction.startStage:
      case LearningTipAction.repeatStage:
        final tpl = TrainingPackTemplateService.getById(tip.targetId, context);
        if (tpl == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TrainingPackPlayScreen(template: tpl, original: tpl),
          ),
        );
        break;
      case LearningTipAction.exploreNextStage:
        // Not implemented yet
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tip;
    if (tip == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: _onAction,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Перейти'),
            )
          ],
        ),
      ),
    );
  }
}
