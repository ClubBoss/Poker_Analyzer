import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';
import '../constants/app_constants.dart';

import '../services/goals_service.dart';
import '../widgets/sync_status_widget.dart';

class MyAchievementsScreen extends StatelessWidget {
  const MyAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои достижения'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Builder(
        builder: (context) {
          final service = context.watch<GoalsService>();
          final completed =
              service.achievements.where((a) => a.completed).toList()
                ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

          if (completed.isEmpty) {
            return const Center(child: Text('Достижения еще не получены'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return GridView.builder(
                padding: responsiveAll(context, AppConstants.defaultPadding),
                itemCount: completed.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final item = completed[index];
                  return Container(
                    padding: responsiveAll(
                      context,
                      AppConstants.defaultPadding * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardCornerRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, size: 40, color: accent),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 1.0,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accent,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${item.target}/${item.target}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
