import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_goal_engine.dart';
import '../models/user_goal.dart';
import '../widgets/sync_status_widget.dart';

class GoalEditorScreen extends StatefulWidget {
  final UserGoal? goal;
  const GoalEditorScreen({super.key, this.goal});

  @override
  State<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends State<GoalEditorScreen> {
  final _title = TextEditingController();
  final _target = TextEditingController(text: '1');
  String _type = 'mistakes';

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g != null) {
      _title.text = g.title;
      _target.text = g.target.toString();
      _type = g.type;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final target = int.tryParse(_target.text) ?? 1;
    if (title.isEmpty) return;
    final engine = context.read<UserGoalEngine>();
    final stats = engine.stats;
    int base;
    if (widget.goal == null) {
      base = {
        'sessions': stats.sessionsCompleted,
        'hands': stats.handsReviewed,
        'mistakes': stats.mistakesFixed,
      }[_type]!;
    } else if (widget.goal!.type == _type) {
      base = widget.goal!.base;
    } else {
      base = {
        'sessions': stats.sessionsCompleted,
        'hands': stats.handsReviewed,
        'mistakes': stats.mistakesFixed,
      }[_type]!;
    }
    final goal = UserGoal(
      id: widget.goal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: _type,
      target: target,
      base: base,
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
      completedAt: widget.goal?.completedAt,
    );
    if (widget.goal == null) {
      await engine.addGoal(goal);
    } else {
      await engine.updateGoal(goal);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Новая цель' : 'Редактирование цели'),
        actions: [
          SyncStatusIcon.of(context),
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: 'mistakes',
                        child: Text('Ошибки'),
                      ),
                      DropdownMenuItem(value: 'hands', child: Text('Раздачи')),
                      DropdownMenuItem(
                        value: 'sessions',
                        child: Text('Сессии'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                    decoration: const InputDecoration(labelText: 'Тип'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Цель'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
