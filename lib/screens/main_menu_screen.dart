import 'package:flutter/material.dart';

import 'player_input_screen.dart';
import 'saved_hands_screen.dart';
import 'training_packs_screen.dart';
import 'all_sessions_screen.dart';
import 'training_history_screen.dart';
import 'my_training_history_screen.dart';
import 'player_zone_demo_screen.dart';
import 'settings_screen.dart';
import 'daily_hand_screen.dart';
import 'spot_of_the_day_screen.dart';
import 'create_pack_screen.dart';
import 'edit_pack_screen.dart';
import 'training_screen.dart';
import 'package:provider/provider.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_spot_of_day_service.dart';
import '../models/training_spot.dart';
import '../user_preferences.dart';
import '../main_demo.dart';
import '../widgets/training_spot_preview.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _demoMode = false;
  TrainingSpot? _spotOfDay;

  @override
  void initState() {
    super.initState();
    _demoMode = UserPreferences.instance.demoMode;
    _loadSpot();
  }

  Future<void> _loadSpot() async {
    final service = const TrainingSpotOfDayService();
    final spot = await service.getSpot();
    if (mounted) {
      setState(() => _spotOfDay = spot);
    }
  }

  Widget _buildSpotOfDaySection(BuildContext context) {
    final spot = _spotOfDay;
    if (spot == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spot of the Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hero stack: ${spot.stacks[spot.heroIndex]}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Positions: ${spot.positions.join(', ')}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TrainingSpotPreview(spot: spot),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrainingScreen(spot: spot)),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDemoMode(bool value) async {
    setState(() => _demoMode = value);
    await UserPreferences.instance.setDemoMode(value);
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PokerAnalyzerDemoApp()),
      );
    }
  }

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
            _buildSpotOfDaySection(context),
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
                  MaterialPageRoute(builder: (_) => const SpotOfTheDayScreen()),
                );
              },
              child: const Text('🎲 Спот дня'),
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
                      builder: (_) => const MyTrainingHistoryScreen()),
                );
              },
              child: const Text('📒 Мои тренировки'),
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
            const SizedBox(height: 16),
            SwitchListTile(
              value: _demoMode,
              title: const Text('Demo Mode'),
              onChanged: _toggleDemoMode,
              activeColor: Colors.orange,
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
