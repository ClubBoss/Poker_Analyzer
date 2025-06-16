import 'package:flutter/material.dart';
import 'poker_analyzer_screen.dart';
import 'settings_screen.dart';
import 'training_packs_screen.dart';
import 'package:provider/provider.dart';
import '../services/action_sync_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/playback_manager_service.dart';
import '../services/stack_manager_service.dart';
import '../services/pot_sync_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_sync_service.dart';
import '../services/board_editing_service.dart';
import '../services/player_editing_service.dart';
import '../services/transition_lock_service.dart';
import '../services/board_reveal_service.dart';
import '../services/folded_players_service.dart';

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
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(create: (_) => PlayerProfileService()),
                          ChangeNotifierProvider(create: (_) => PlayerManagerService(context.read<PlayerProfileService>())),
                        ],
                        child: Builder(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) {
                              final potSync = PotSyncService();
                              final stackService = StackManagerService(
                                Map<int, int>.from(
                                    context.read<PlayerManagerService>().initialStacks),
                                potSync: potSync,
                              );
                              return PlaybackManagerService(
                                actions: context.read<ActionSyncService>().analyzerActions,
                                stackService: stackService,
                                potSync: potSync,
                                actionSync: context.read<ActionSyncService>(),
                              );
                            },
                            child: Builder(
                          builder: (context) => Provider(
                            create: (_) => BoardSyncService(
                              playerManager: context.read<PlayerManagerService>(),
                              actionSync: context.read<ActionSyncService>(),
                            ),
                            child: Builder(
                              builder: (context) {
                                final lockService = TransitionLockService();
                                final reveal = BoardRevealService(
                                  lockService: lockService,
                                  boardSync: context.read<BoardSyncService>(),
                                );
                                return MultiProvider(
                                  providers: [
                                    Provider<BoardRevealService>.value(
                                        value: reveal),
                                    ChangeNotifierProvider(
                                      create: (_) => BoardManagerService(
                                        playerManager:
                                            context.read<PlayerManagerService>(),
                                        actionSync:
                                            context.read<ActionSyncService>(),
                                        playbackManager:
                                            context.read<PlaybackManagerService>(),
                                        lockService: lockService,
                                        boardSync: context.read<BoardSyncService>(),
                                        boardReveal: reveal,
                                      ),
                                    ),
                                    Provider(
                                      create: (_) => BoardEditingService(
                                        boardManager:
                                            context.read<BoardManagerService>(),
                                        boardSync: context.read<BoardSyncService>(),
                                        playerManager:
                                            context.read<PlayerManagerService>(),
                                        profile: context.read<PlayerProfileService>(),
                                      ),
                                    ),
                                    Provider(
                                      create: (_) => PlayerEditingService(
                                        playerManager: context.read<PlayerManagerService>(),
                                        stackService: context.read<PlaybackManagerService>().stackService,
                                        playbackManager: context.read<PlaybackManagerService>(),
                                      ),
                                    ),
                                  ],
                                  child: Builder(
                                    builder: (context) => PokerAnalyzerScreen(
                                      key: key,
                                      actionSync:
                                          context.read<ActionSyncService>(),
                                      foldedPlayersService:
                                          context.read<FoldedPlayersService>(),
                                      handContext: CurrentHandContextService(),
                                      playbackManager:
                                          context.read<PlaybackManagerService>(),
                                      stackService: context
                                          .read<PlaybackManagerService>()
                                          .stackService,
                                      potSyncService: context
                                          .read<PlaybackManagerService>()
                                          .potSync,
                                      boardManager:
                                          context.read<BoardManagerService>(),
                                      boardSync:
                                          context.read<BoardSyncService>(),
                                      boardEditing:
                                          context.read<BoardEditingService>(),
                                      playerEditing:
                                          context.read<PlayerEditingService>(),
                                      playerManager:
                                          context.read<PlayerManagerService>(),
                                      playerProfile:
                                          context.read<PlayerProfileService>(),
                                  actionTagService: context
                                      .read<PlayerProfileService>()
                                      .actionTagService,
                                  boardReveal:
                                      context.read<BoardRevealService>(),
                                  lockService: lockService,
                                ),
                              ),
                              );
                              },
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
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(create: (_) => PlayerProfileService()),
                          ChangeNotifierProvider(create: (_) => PlayerManagerService(context.read<PlayerProfileService>())),
                        ],
                        child: Builder(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) {
                              final potSync = PotSyncService();
                              final stackService = StackManagerService(
                                Map<int, int>.from(
                                    context.read<PlayerManagerService>().initialStacks),
                                potSync: potSync,
                              );
                              return PlaybackManagerService(
                                actions: context.read<ActionSyncService>().analyzerActions,
                                stackService: stackService,
                                potSync: potSync,
                                actionSync: context.read<ActionSyncService>(),
                              );
                            },
                            child: Builder(
                          builder: (context) => Provider(
                            create: (_) => BoardSyncService(
                              playerManager: context.read<PlayerManagerService>(),
                              actionSync: context.read<ActionSyncService>(),
                            ),
                            child: Builder(
                              builder: (context) {
                                final lockService = TransitionLockService();
                                final reveal = BoardRevealService(
                                  lockService: lockService,
                                  boardSync: context.read<BoardSyncService>(),
                                );
                                return MultiProvider(
                                  providers: [
                                    Provider<BoardRevealService>.value(
                                        value: reveal),
                                    ChangeNotifierProvider(
                                      create: (_) => BoardManagerService(
                                        playerManager:
                                            context.read<PlayerManagerService>(),
                                        actionSync:
                                            context.read<ActionSyncService>(),
                                        playbackManager:
                                            context.read<PlaybackManagerService>(),
                                        lockService: lockService,
                                        boardSync: context.read<BoardSyncService>(),
                                        boardReveal: reveal,
                                      ),
                                    ),
                                    Provider(
                                      create: (_) => BoardEditingService(
                                        boardManager:
                                            context.read<BoardManagerService>(),
                                        boardSync: context.read<BoardSyncService>(),
                                        playerManager:
                                            context.read<PlayerManagerService>(),
                                        profile: context.read<PlayerProfileService>(),
                                      ),
                                    ),
                                    Provider(
                                      create: (_) => PlayerEditingService(
                                        playerManager: context.read<PlayerManagerService>(),
                                        stackService: context.read<PlaybackManagerService>().stackService,
                                        playbackManager: context.read<PlaybackManagerService>(),
                                      ),
                                    ),
                                  ],
                                  child: Builder(
                                    builder: (context) => PokerAnalyzerScreen(
                                      actionSync:
                                          context.read<ActionSyncService>(),
                                      handContext: CurrentHandContextService(),
                                      playbackManager:
                                          context.read<PlaybackManagerService>(),
                                      stackService: context
                                          .read<PlaybackManagerService>()
                                          .stackService,
                                      potSyncService: context
                                          .read<PlaybackManagerService>()
                                          .potSync,
                                      boardManager:
                                          context.read<BoardManagerService>(),
                                      boardSync:
                                          context.read<BoardSyncService>(),
                                      boardEditing:
                                          context.read<BoardEditingService>(),
                                      playerEditing:
                                          context.read<PlayerEditingService>(),
                                      playerManager:
                                          context.read<PlayerManagerService>(),
                                      playerProfile:
                                          context.read<PlayerProfileService>(),
                                      actionTagService: context
                                          .read<PlayerProfileService>()
                                          .actionTagService,
                                  boardReveal:
                                      context.read<BoardRevealService>(),
                                  lockService: lockService,
                                ),
                              ),
                              );
                              },
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
