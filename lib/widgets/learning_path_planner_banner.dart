import 'package:flutter/material.dart';

import '../services/learning_path_orchestrator.dart';
import '../screens/learning_path_week_planner_screen.dart';

/// Banner that links to the weekly learning plan.
class LearningPathPlannerBanner extends StatefulWidget {
  const LearningPathPlannerBanner({super.key});

  @override
  State<LearningPathPlannerBanner> createState() =>
      _LearningPathPlannerBannerState();
}

class _LearningPathPlannerBannerState extends State<LearningPathPlannerBanner>
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
    _load();
  }

  Future<void> _load() async {
    final path = await LearningPathOrchestrator.instance.resolve();
    if (mounted && path.stages.isNotEmpty) {
      setState(() => _visible = true);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LearningPathWeekPlannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Your weekly plan is ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _openPlanner,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('View Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
