import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/training_goal.dart';
import '../services/goal_reengagement_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_session_launcher.dart';

/// Inline banner prompting the user to continue a stale training goal.
class GoalReengagementBannerWidget extends StatefulWidget {
  const GoalReengagementBannerWidget({super.key});

  @override
  State<GoalReengagementBannerWidget> createState() =>
      _GoalReengagementBannerWidgetState();
}

class _GoalReengagementBannerWidgetState
    extends State<GoalReengagementBannerWidget> {
  bool _loading = true;
  TrainingGoal? _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final service = context.read<GoalReengagementService>();
    final goal = await service.pickReengagementGoal();
    if (mounted) {
      setState(() {
        _goal = goal;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final tag = _goal?.tag?.toLowerCase();
    if (tag == null) return;
    await PackLibraryLoaderService.instance.loadLibrary();
    final pack = PackLibraryLoaderService.instance.library.firstWhereOrNull(
      (p) => p.tags.map((e) => e.toLowerCase()).contains(tag),
    );
    if (pack != null) {
      await const TrainingSessionLauncher().launch(pack);
    }
  }

  Future<void> _dismiss() async {
    final tag = _goal?.tag;
    if (tag == null) return;
    await context.read<GoalReengagementService>().markDismissed(tag);
    if (mounted) setState(() => _goal = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final tag = _goal!.tag ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '\u041F\u0440\u043E\u0434\u043E\u043B\u0436\u0438\u043C \u0446\u0435\u043B\u044C: $tag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text(
                  '\u0422\u0440\u0435\u043D\u0438\u0440\u043E\u0432\u0430\u0442\u044C',
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _dismiss,
                child: const Text('\u0421\u043A\u0440\u044B\u0442\u044C'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
