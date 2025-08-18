import 'package:flutter/material.dart';

import '../services/block_completion_reward_service.dart';
import 'confetti_overlay.dart';
import '../services/achievement_service.dart';
import '../services/achievement_trigger_engine.dart';

class StageCompletionBanner extends StatefulWidget {
  final String title;
  final int levelIndex;
  final String goal;
  const StageCompletionBanner({
    super.key,
    required this.title,
    required this.levelIndex,
    required this.goal,
  });

  @override
  State<StageCompletionBanner> createState() => _StageCompletionBannerState();
}

class _StageCompletionBannerState extends State<StageCompletionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _check();
  }

  Future<void> _check() async {
    final show = await BlockCompletionRewardService.instance.isStageCompleted(
      widget.title,
    );
    if (show && mounted) {
      setState(() => _visible = true);
      _controller.forward();
      showConfettiOverlay(context);
      AchievementService.instance.checkAll();
      await AchievementTriggerEngine.instance.checkAndTriggerAchievements();
      await BlockCompletionRewardService.instance.markBannerShown(widget.title);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          '🎯 Цель достигнута: ${widget.goal}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
