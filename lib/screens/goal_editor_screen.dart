import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goal_engine.dart';
import '../models/user_goal.dart';

class GoalEditorScreen extends StatefulWidget {
  const GoalEditorScreen({super.key});

  @override
  State<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends State<GoalEditorScreen> {
  final _title = TextEditingController();
  final _target = TextEditingController(text: '1');
  String _type = 'mistakes';

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
    final stats = context.read<GoalEngine>().stats;
    final base = {
      'sessions': stats.sessionsCompleted,
      'hands': stats.handsReviewed,
      'mistakes': stats.mistakesFixed,
    }[_type]!;
    final goal = UserGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: _type,
      target: target,
      base: base,
      createdAt: DateTime.now(),
    );
    await context.read<GoalEngine>().addGoal(goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая цель'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check))
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
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'mistakes', child: Text('Ошибки')),
                      DropdownMenuItem(value: 'hands', child: Text('Раздачи')),
                      DropdownMenuItem(value: 'sessions', child: Text('Сессии')),
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
