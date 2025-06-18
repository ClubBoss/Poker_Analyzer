import 'package:flutter/material.dart';

import 'player_input_screen.dart';
import 'saved_hands_screen.dart';
import 'training_packs_screen.dart';
import 'all_sessions_screen.dart';
import 'training_history_screen.dart';
import 'player_zone_demo_screen.dart';
import 'settings_screen.dart';
import 'daily_hand_screen.dart';
import 'create_pack_screen.dart';
import 'edit_pack_screen.dart';
import 'package:provider/provider.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Poker AI Analyzer'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerInputScreen()),
                );
              },
              child: const Text('➕ Новая раздача'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyHandScreen()),
                );
              },
              child: const Text('🃏 Ежедневная раздача'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedHandsScreen()),
                );
              },
              child: const Text('📂 Сохранённые раздачи'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingPacksScreen()),
                );
              },
              child: const Text('🎯 Тренировка'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreatePackScreen(),
                  ),
                );
              },
              child: const Text('📦 Создать тренировку'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditPackScreen(),
                  ),
                );
              },
              child: const Text('✏️ Редактировать тренировку'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
                );
              },
              child: const Text('📈 История тренировок'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingHistoryScreen()),
                );
              },
              child: const Text('🗓️ Training History'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlayerZoneDemoScreen()),
                );
              },
              child: const Text('🧪 Player Zone Demo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('⚙️ Settings'),
            ),
            const SizedBox(height: 32),
            const Text(
              '🛠️ Инструменты',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final manager =
                    Provider.of<SavedHandManagerService>(context, listen: false);
                final service = HandHistoryFileService(manager);
                await service.importFromFiles(context);
              },
              child: const Text('Импортировать Hand History'),
            ),
          ],
        ),
      ),
    );
  }
}
