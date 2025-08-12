import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/streak_service.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';

class AchievementsCatalogScreen extends StatelessWidget {
  const AchievementsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог достижений'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Builder(
        builder: (context) {
          final handManager = context.watch<SavedHandManagerService>();
          final eval = context.watch<EvaluationExecutorService>();
          final streak = context.watch<StreakService>().count;
          final goals = context.watch<GoalsService>();

          final summary = eval.summarizeHands(handManager.hands);
          goals.updateAchievements(
            context: context,
            correctHands: summary.correct,
            streakDays: streak,
            goalCompleted: goals.anyCompleted,
          );

          final data = goals.achievements;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return GridView.builder(
                padding: responsiveAll(context, 16),
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
              final item = data[index];
              final completed = item.completed;
              final color = completed ? Colors.white : Colors.white54;
              final highlight =
                  item.title == 'Без ошибок подряд' &&
                      goals.errorFreeStreak >= 3;
              Widget icon = Icon(item.icon, size: 40, color: accent);
              if (!completed) {
                icon = ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  child: icon,
                );
              }
              Widget card = Container(
                padding: responsiveAll(context, 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: highlight
                      ? Border.all(color: accent, width: 2)
                      : null,
                  boxShadow: highlight
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: completed
                                    ? 1.0
                                    : (item.progress / item.target)
                                        .clamp(0.0, 1.0),
                              ),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accent),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.progress}/${item.target}',
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!completed)
                      const Text(
                        'Не выполнено',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
                if (completed)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
              ],
            ),
          );
              if (highlight) {
                card = Tooltip(
                  message: 'Держите темп!',
                  triggerMode: TooltipTriggerMode.longPress,
                  child: card,
                );
              }
              return card;
            },
          );
        },
      ),
    );
  }
}
