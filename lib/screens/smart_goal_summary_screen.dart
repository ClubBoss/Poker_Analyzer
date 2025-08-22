import 'package:flutter/material.dart';
import '../models/xp_guided_goal.dart';
import '../services/goal_inbox_delivery_controller.dart';
import '../services/goal_slot_allocator.dart';
import '../services/booster_path_history_service.dart';
import '../services/goal_to_training_launcher.dart';
import '../services/mini_lesson_library_service.dart';

class SmartGoalSummaryScreen extends StatefulWidget {
  const SmartGoalSummaryScreen({super.key});

  @override
  State<SmartGoalSummaryScreen> createState() => _SmartGoalSummaryScreenState();
}

class _GoalItem {
  final XPGuidedGoal goal;
  final String tag;
  bool completed;
  _GoalItem({required this.goal, required this.tag, this.completed = false});
}

class _SmartGoalSummaryScreenState extends State<SmartGoalSummaryScreen> {
  bool _loading = true;
  final Map<String, List<_GoalItem>> _bySlot = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = GoalInboxDeliveryController.instance;
    final goals = await controller.getInboxGoals(maxGoals: 10);
    final assignments = await GoalSlotAllocator.instance.allocate(goals);
    await MiniLessonLibraryService.instance.loadAll();
    final history = await BoosterPathHistoryService.instance.getTagStats();
    final map = <String, List<_GoalItem>>{};
    for (final a in assignments) {
      final lesson = MiniLessonLibraryService.instance.getById(a.goal.id);
      final tag = lesson != null && lesson.tags.isNotEmpty
          ? lesson.tags.first
          : '';
      final completed = (history[tag.toLowerCase()]?.completedCount ?? 0) > 0;
      final item = _GoalItem(goal: a.goal, tag: tag, completed: completed);
      map.putIfAbsent(a.slot, () => []).add(item);
    }
    if (!mounted) return;
    setState(() {
      _bySlot
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  Future<void> _start(_GoalItem item) async {
    await const GoalToTrainingLauncher().launchFromGoal(item.goal);
    if (!mounted) return;
    await _load();
  }

  Widget _goalTile(_GoalItem item) {
    final accent = Theme.of(context).colorScheme.secondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.goal.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.tag.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '#${item.tag}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${item.goal.xp} XP',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          item.completed
              ? const Icon(Icons.check, color: Colors.greenAccent)
              : ElevatedButton(
                  onPressed: () => _start(item),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Start'),
                ),
        ],
      ),
    );
  }

  Widget _section(String title, List<_GoalItem>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final g in items) _goalTile(g),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XP Goals Overview')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('🏠 Home Priorities', _bySlot['home']),
                  _section('📚 Theory Boosters', _bySlot['theory']),
                  _section(
                    '🕓 Post-Recap Reinforcements',
                    _bySlot['postrecap'],
                  ),
                ],
              ),
            ),
    );
  }
}
