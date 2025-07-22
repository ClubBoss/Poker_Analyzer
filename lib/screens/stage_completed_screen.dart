import 'package:flutter/material.dart';
import '../widgets/confetti_overlay.dart';
import '../services/learning_path_registry_service.dart';
import 'learning_path_screen_v2.dart';

/// Shown when a learning path stage is completed successfully.
class StageCompletedScreen extends StatefulWidget {
  final String pathId;
  final String stageTitle;
  final double accuracy;
  final int hands;
  const StageCompletedScreen({
    super.key,
    required this.pathId,
    required this.stageTitle,
    required this.accuracy,
    required this.hands,
  });

  @override
  State<StageCompletedScreen> createState() => _StageCompletedScreenState();
}

class _StageCompletedScreenState extends State<StageCompletedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  void _continue() {
    final template = LearningPathRegistryService.instance.findById(widget.pathId);
    if (template != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LearningPathScreen(
            template: template,
            highlightedStageId: null,
          ),
        ),
      );
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.accuracy.toStringAsFixed(1);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Well done!',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                widget.stageTitle,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text('Hands completed: ${widget.hands}',
                  style: const TextStyle(fontSize: 16)),
              Text('Accuracy: $acc%',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue Path'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
