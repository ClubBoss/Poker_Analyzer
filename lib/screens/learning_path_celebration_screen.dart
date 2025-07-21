import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';
import '../services/learning_path_progress_tracker_service.dart';
import '../services/learning_path_progress_service.dart';
import '../services/session_log_service.dart';
import '../widgets/confetti_overlay.dart';

/// Displays a celebratory summary once a learning path is fully completed.
class LearningPathCelebrationScreen extends StatefulWidget {
  /// Completed learning path template.
  final LearningPathTemplateV2 path;

  /// Optional callback when user wants to proceed to the next path.
  final VoidCallback? onNext;

  /// Whether to show share button.
  final bool allowShare;

  const LearningPathCelebrationScreen({
    super.key,
    required this.path,
    this.onNext,
    this.allowShare = true,
  });

  @override
  State<LearningPathCelebrationScreen> createState() =>
      _LearningPathCelebrationScreenState();
}

class _LearningPathCelebrationScreenState
    extends State<LearningPathCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Map<String, SessionLog> _logs = const {};

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context, particlePath: _starPath);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final logs = context.read<SessionLogService>().logs;
    _logs = const LearningPathProgressTrackerService().aggregateLogsByPack(logs);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  int get _totalHands {
    var total = 0;
    for (final s in widget.path.stages) {
      final log = _logs[s.packId];
      if (log != null) {
        total += log.correctCount + log.mistakeCount;
      }
    }
    return total;
  }

  double get _accuracy {
    var correct = 0;
    var total = 0;
    for (final s in widget.path.stages) {
      final log = _logs[s.packId];
      if (log != null) {
        correct += log.correctCount;
        total += log.correctCount + log.mistakeCount;
      }
    }
    if (total == 0) return 0.0;
    return correct / total * 100;
  }

  Path _starPath(Size size) {
    const points = 5;
    final halfWidth = size.width / 2;
    final external = halfWidth;
    final internal = halfWidth / 2.5;
    final center = Offset(halfWidth, halfWidth);
    final path = Path();
    final step = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? external : internal;
      final angle = step * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _share() {
    final text =
        'Я завершил путь "${widget.path.title}" c точностью ${_accuracy.toStringAsFixed(1)}% в Poker Analyzer!';
    Share.share(text);
  }

  void _next() {
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _repeat() async {
    await LearningPathProgressService.instance.resetProgress();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _anim, curve: Curves.easeIn),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale:
                      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
                  child: const Icon(Icons.emoji_events,
                      color: Colors.amber, size: 96),
                ),
              const SizedBox(height: 24),
              const Text(
                'Поздравляем!',
                style: TextStyle(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.path.title,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('Рук сыграно: $_totalHands',
                  style: const TextStyle(fontSize: 16)),
              Text('Точность: ${_accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _next,
                child: const Text('Перейти к следующему пути'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(
                  onPressed: _repeat,
                  child: const Text('Повторить путь'),
                ),
              ),
              if (widget.allowShare)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться достижением'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

