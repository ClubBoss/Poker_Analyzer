import 'package:flutter/material.dart';

import '../models/training_goal.dart';
import '../services/tag_goal_tracker_service.dart';

/// Floating overlay showing progress for the active booster goal
/// and the accuracy change for the current tag.
class BoosterProgressOverlay extends StatefulWidget {
  final TrainingGoal activeGoal;
  final String currentTag;
  final double accuracyBefore;
  final double accuracyAfter;
  final Duration duration;
  final VoidCallback onCompleted;

  const BoosterProgressOverlay({
    super.key,
    required this.activeGoal,
    required this.currentTag,
    required this.accuracyBefore,
    required this.accuracyAfter,
    this.duration = const Duration(seconds: 3),
    required this.onCompleted,
  });

  @override
  State<BoosterProgressOverlay> createState() => _BoosterProgressOverlayState();
}

class _BoosterProgressOverlayState extends State<BoosterProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _pulse;
  int _completed = 0;
  int _target = 0;

  @override
  void initState() {
    super.initState();
    final match = RegExp(r'(\d+)').firstMatch(widget.activeGoal.title);
    _target = match != null ? int.parse(match.group(0)!) : 0;
    TagGoalTrackerService.instance
        .getProgress(widget.currentTag)
        .then((p) {
      if (mounted) setState(() => _completed = p.trainings);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_controller);
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onCompleted());
      } else {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = (widget.accuracyAfter - widget.accuracyBefore) * 100;
    final up = delta >= 0;
    final color = up ? Colors.greenAccent : Colors.redAccent;
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Goal: $_completed/$_target boosters completed for ${widget.currentTag}',
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            up ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Accuracy ${up ? '+' : '-'}${delta.abs().toStringAsFixed(1)}%',
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to display [BoosterProgressOverlay] above the current screen.
void showBoosterProgressOverlay(
  BuildContext context, {
  required TrainingGoal activeGoal,
  required String currentTag,
  required double accuracyBefore,
  required double accuracyAfter,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => BoosterProgressOverlay(
      activeGoal: activeGoal,
      currentTag: currentTag,
      accuracyBefore: accuracyBefore,
      accuracyAfter: accuracyAfter,
      duration: duration,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
