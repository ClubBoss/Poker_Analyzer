import 'package:flutter/material.dart';

class AchievementCatalogEntry {
  final String title;
  final IconData icon;
  final int progress;
  final int target;

  const AchievementCatalogEntry({
    required this.title,
    required this.icon,
    required this.progress,
    required this.target,
  });

  bool get completed => progress >= target;
}

class AchievementsCatalogScreen extends StatelessWidget {
  const AchievementsCatalogScreen({super.key});

  static const List<AchievementCatalogEntry> _mockData = [
    AchievementCatalogEntry(
      title: 'Разобрать 5 ошибок',
      icon: Icons.bug_report,
      progress: 2,
      target: 5,
    ),
    AchievementCatalogEntry(
      title: '3 дня подряд',
      icon: Icons.local_fire_department,
      progress: 1,
      target: 3,
    ),
    AchievementCatalogEntry(
      title: 'Цель выполнена',
      icon: Icons.flag,
      progress: 0,
      target: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог достижений'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockData.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final item = _mockData[index];
          final completed = item.completed;
          final color = completed ? Colors.white : Colors.white54;
          Widget icon = Icon(item.icon, size: 40, color: accent);
          if (!completed) {
            icon = ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: icon,
            );
          }
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
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
                            child: LinearProgressIndicator(
                              value: completed
                                  ? 1.0
                                  : (item.progress / item.target)
                                      .clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                              minHeight: 6,
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
        },
      ),
    );
  }
}
