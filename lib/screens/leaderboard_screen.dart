import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/leaderboard_service.dart';
import '../theme/app_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<LeaderboardService>().entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e = entries[i];
          final name = e.uuid.length >= 4
              ? e.uuid.substring(e.uuid.length - 4)
              : e.uuid;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Text(
                '#${i + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              title: Text(
                'User $name',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'H: ${e.handsReviewed}',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                  Text(
                    'M: ${e.mistakesFixed}',
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
