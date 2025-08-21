import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'poker_analyzer_screen.dart';
import '../services/action_sync_service.dart';
import '../services/all_in_players_service.dart';
import '../services/board_editing_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_reveal_service.dart';
import '../services/board_sync_service.dart';
import '../services/current_hand_context_service.dart';
import '../services/folded_players_service.dart';
import '../services/player_editing_service.dart';
import '../services/player_manager_service.dart';
import '../services/player_profile_service.dart';
import '../services/playback_manager_service.dart';
import '../services/pot_history_service.dart';
import '../services/pot_sync_service.dart';
import '../services/stack_manager_service.dart';
import '../services/transition_lock_service.dart';
import '../services/action_history_service.dart';
import '../services/training_import_export_service.dart';
import '../widgets/primary_weakness_drill_card.dart';
import '../widgets/repeat_last_incorrect_card.dart';
import '../widgets/top_mistake_drill_card.dart';
import '../widgets/top_categories_drill_card.dart';
import '../widgets/category_drill_card.dart';
import '../widgets/last_mistake_drill_card.dart';

class AnalyzerTab extends StatelessWidget {
  const AnalyzerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProfileService()),
        ChangeNotifierProvider(
          create: (context) =>
              PlayerManagerService(context.read<PlayerProfileService>()),
        ),
        ChangeNotifierProvider(create: (_) => AllInPlayersService()),
        ChangeNotifierProvider(create: (_) => FoldedPlayersService()),
        ChangeNotifierProvider(
          create: (context) => ActionSyncService(
            foldedPlayers: context.read<FoldedPlayersService>(),
            allInPlayers: context.read<AllInPlayersService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final history = PotHistoryService();
            final potSync = PotSyncService(historyService: history);
            final stackService = StackManagerService(
              Map<int, int>.from(
                context.read<PlayerManagerService>().initialStacks,
              ),
              potSync: potSync,
            );
            return PlaybackManagerService(
              stackService: stackService,
              potSync: potSync,
              actionSync: context.read<ActionSyncService>(),
            );
          },
        ),
        Provider(
          create: (context) => BoardSyncService(
            playerManager: context.read<PlayerManagerService>(),
            actionSync: context.read<ActionSyncService>(),
          ),
        ),
        Provider(create: (_) => ActionHistoryService()),
        Provider(create: (_) => const TrainingImportExportService()),
      ],
      child: Builder(
        builder: (context) {
          final lockService = TransitionLockService();
          final boardReveal = BoardRevealService(
            lockService: lockService,
            boardSync: context.read<BoardSyncService>(),
          );
          return MultiProvider(
            providers: [
              Provider<TransitionLockService>.value(value: lockService),
              Provider<BoardRevealService>.value(value: boardReveal),
              ChangeNotifierProvider(
                create: (_) => BoardManagerService(
                  playerManager: context.read<PlayerManagerService>(),
                  actionSync: context.read<ActionSyncService>(),
                  playbackManager: context.read<PlaybackManagerService>(),
                  lockService: lockService,
                  boardSync: context.read<BoardSyncService>(),
                  boardReveal: boardReveal,
                ),
              ),
              Provider(
                create: (_) => BoardEditingService(
                  boardManager: context.read<BoardManagerService>(),
                  boardSync: context.read<BoardSyncService>(),
                  playerManager: context.read<PlayerManagerService>(),
                  profile: context.read<PlayerProfileService>(),
                ),
              ),
              Provider(
                create: (_) => PlayerEditingService(
                  playerManager: context.read<PlayerManagerService>(),
                  stackService:
                      context.read<PlaybackManagerService>().stackService,
                  playbackManager: context.read<PlaybackManagerService>(),
                  profile: context.read<PlayerProfileService>(),
                ),
              ),
            ],
            child: Column(
              children: [
                const PrimaryWeaknessDrillCard(),
                const RepeatLastIncorrectCard(),
                const TopMistakeDrillCard(),
                const TopCategoriesDrillCard(),
                const CategoryDrillCard(),
                const LastMistakeDrillCard(),
                Expanded(
                  child: PokerAnalyzerScreen(
                    actionSync: context.read<ActionSyncService>(),
                    foldedPlayersService: context.read<FoldedPlayersService>(),
                    allInPlayersService: context.read<AllInPlayersService>(),
                    handContext: CurrentHandContextService(),
                    playbackManager: context.read<PlaybackManagerService>(),
                    stackService:
                        context.read<PlaybackManagerService>().stackService,
                    potSyncService:
                        context.read<PlaybackManagerService>().potSync,
                    boardManager: context.read<BoardManagerService>(),
                    boardSync: context.read<BoardSyncService>(),
                    boardEditing: context.read<BoardEditingService>(),
                    playerEditing: context.read<PlayerEditingService>(),
                    playerManager: context.read<PlayerManagerService>(),
                    playerProfile: context.read<PlayerProfileService>(),
                    actionTagService:
                        context.read<PlayerProfileService>().actionTagService,
                    boardReveal: boardReveal,
                    lockService: lockService,
                    actionHistory: context.read<ActionHistoryService>(),
                    demoMode: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
