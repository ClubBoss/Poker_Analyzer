import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';
import '../screens/skill_map_screen.dart';
import '../screens/tag_insight_screen.dart';

class TagProgressCard extends StatelessWidget {
  const TagProgressCard({super.key});

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  Future<List<MapEntry<String, double>>> _load(BuildContext context) async {
    final map = await context.read<TagMasteryService>().computeMastery();
    final list = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list.take(3).toList();
  }

  void _openTag(BuildContext context, String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
    );
  }

  void _openSkillMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SkillMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, double>>>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final list = snapshot.data!;
        if (list.isEmpty) return const SizedBox.shrink();

        Widget row(MapEntry<String, double> e) {
          final value = e.value.clamp(0.0, 1.0);
          final color =
              Color.lerp(Colors.red, Colors.green, value) ?? Colors.red;
          final icon = value < 0.3 ? ' ⚠️' : '';
          final name = _capitalize(e.key);
          return GestureDetector(
            onTap: () => _openTag(context, e.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name$icon',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(value * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openSkillMap(context),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      'Слабые навыки',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final e in list) row(e),
              ],
            ),
          ),
        );
      },
    );
  }
}
