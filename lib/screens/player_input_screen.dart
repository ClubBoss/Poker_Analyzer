import 'package:flutter/material.dart';
import 'poker_analyzer_screen.dart';
import 'settings_screen.dart';
import 'training_packs_screen.dart';
import 'package:provider/provider.dart';
import '../services/action_sync_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/player_manager_service.dart';
import '../services/playback_manager_service.dart';
import '../services/stack_manager_service.dart';

class PlayerInputScreen extends StatefulWidget {
  const PlayerInputScreen({super.key});

  @override
  State<PlayerInputScreen> createState() => _PlayerInputScreenState();
}

class _PlayerInputScreenState extends State<PlayerInputScreen> {
  final TextEditingController _controller = TextEditingController();
  int _selectedPlayers = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Poker AI Analyzer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Введите описание раздачи',
                hintText: 'Пример: UTG рейз 2bb, MP колл, BB пуш 20bb...',
                labelStyle: TextStyle(color: Colors.white),
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Игроков за столом: ',
                  style: TextStyle(color: Colors.white),
                ),
                DropdownButton<int>(
                  value: _selectedPlayers,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white),
                  items: List.generate(8, (index) => index + 2)
                      .map((e) => DropdownMenuItem<int>(
                            value: e,
                            child: Text(e.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPlayers = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final data = await Navigator.push<Map<String, dynamic>?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPacksScreen(),
                  ),
                );
                if (data != null) {
                  final key = GlobalKey();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => PlayerManagerService(),
                        child: Builder(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => PlaybackManagerService(
                              actions: context
                                  .read<ActionSyncService>()
                                  .analyzerActions,
                              stackService: StackManagerService(
                                Map<int, int>.from(
                                    context.read<PlayerManagerService>().initialStacks),
                              ),
                              actionSync: context.read<ActionSyncService>(),
                            ),
                            child: Builder(
                              builder: (context) => PokerAnalyzerScreen(
                                key: key,
                                actionSync: context.read<ActionSyncService>(),
                                handContext: CurrentHandContextService(),
                                playbackManager:
                                    context.read<PlaybackManagerService>(),
                                stackService: context
                                    .read<PlaybackManagerService>()
                                    .stackService,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final state = key.currentState as dynamic;
                    state?.loadTrainingSpot(data);
                  });
                }
              },
              child: const Text('📦 Выбрать тренировку'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => PlayerManagerService(),
                        child: Builder(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => PlaybackManagerService(
                              actions: context
                                  .read<ActionSyncService>()
                                  .analyzerActions,
                              stackService: StackManagerService(
                                Map<int, int>.from(
                                    context.read<PlayerManagerService>().initialStacks),
                              ),
                              actionSync: context.read<ActionSyncService>(),
                            ),
                            child: Builder(
                              builder: (context) => PokerAnalyzerScreen(
                                actionSync: context.read<ActionSyncService>(),
                                handContext: CurrentHandContextService(),
                                playbackManager:
                                    context.read<PlaybackManagerService>(),
                                stackService: context
                                    .read<PlaybackManagerService>()
                                    .stackService,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('Анализировать'),
            ),
          ],
        ),
      ),
    );
  }
}
