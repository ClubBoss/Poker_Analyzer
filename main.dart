import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poker_analyzer/core/plugin_runtime.dart';
import 'package:poker_analyzer/theme/app_colors.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:poker_analyzer/screens/poker_analyzer_screen.dart';
import 'package:poker_analyzer/services/action_sync_service.dart';
import 'package:poker_analyzer/services/all_in_players_service.dart';
import 'package:poker_analyzer/services/board_editing_service.dart';
import 'package:poker_analyzer/services/board_manager_service.dart';
import 'package:poker_analyzer/services/board_reveal_service.dart';
import 'package:poker_analyzer/services/board_sync_service.dart';
import 'package:poker_analyzer/services/current_hand_context_service.dart';
import 'package:poker_analyzer/services/folded_players_service.dart';
import 'package:poker_analyzer/services/player_editing_service.dart';
import 'package:poker_analyzer/services/player_manager_service.dart';
import 'package:poker_analyzer/services/player_profile_service.dart';
import 'package:poker_analyzer/services/playback_manager_service.dart';
import 'package:poker_analyzer/services/pot_history_service.dart';
import 'package:poker_analyzer/services/pot_sync_service.dart';
import 'package:poker_analyzer/services/stack_manager_service.dart';
import 'package:poker_analyzer/services/transition_lock_service.dart';
import 'package:poker_analyzer/services/action_history_service.dart';
import 'package:poker_analyzer/services/training_import_export_service.dart';
import 'package:poker_analyzer/services/demo_playback_controller.dart';

final PluginRuntime pluginRuntime = PluginRuntime();

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information.')
    ..addFlag(
      'demo',
      defaultsTo: true,
      help: 'Run application in demo mode.',
    );

  late ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    // Invalid arguments supplied, print error and usage.
    print(e.message);
    print(parser.usage);
    return;
  }

  if (results['help'] as bool) {
    print('Usage: poker_analyzer [options]');
    print(parser.usage);
    return;
  }

  final demoMode = results['demo'] as bool;

  WidgetsFlutterBinding.ensureInitialized();
  await pluginRuntime.initialize();
  runApp(PokerAnalyzerDemoApp(demoMode: demoMode));
}

class PokerAnalyzerDemoApp extends StatefulWidget {
  const PokerAnalyzerDemoApp({super.key, this.demoMode = true});

  final bool demoMode;

  @override
  State<PokerAnalyzerDemoApp> createState() => _PokerAnalyzerDemoAppState();
}

class _PokerAnalyzerDemoAppState extends State<PokerAnalyzerDemoApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _labelController.reverse();
    _labelController.dispose();
    super.dispose();
  }

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
              Provider(
                create: (_) => DemoPlaybackController(
                  playbackManager: context.read<PlaybackManagerService>(),
                  boardManager: context.read<BoardManagerService>(),
                  importExportService:
                      context.read<TrainingImportExportService>(),
                  potSync: context.read<PlaybackManagerService>().potSync,
                ),
              ),
            ],
            child: MaterialApp(
              title: 'Poker AI Analyzer Demo',
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
                scaffoldBackgroundColor: AppColors.background,
                cardColor: AppColors.cardBackground,
                textTheme: ThemeData.dark().textTheme.apply(
                      fontFamily: 'Roboto',
                      bodyColor: AppColors.textPrimaryDark,
                      displayColor: AppColors.textPrimaryDark,
                    ),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('fr'),
                Locale('ru'),
                Locale('pt'),
                Locale('de'),
              ],
              builder: (context, child) {
                return Stack(
                  children: [
                    if (child != null) child,
                    if (widget.demoMode)
                      Positioned(
                        bottom: MediaQuery.of(context).padding.bottom + 8,
                        left: 8,
                        child: FadeTransition(
                          opacity: _labelController,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimaryDark
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Demo Mode Active',
                              style: TextStyle(
                                color: AppColors.textPrimaryDark
                                    .withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              home: PokerAnalyzerScreen(
                actionSync: context.read<ActionSyncService>(),
                foldedPlayersService: context.read<FoldedPlayersService>(),
                allInPlayersService: context.read<AllInPlayersService>(),
                handContext: CurrentHandContextService(),
                playbackManager: context.read<PlaybackManagerService>(),
                stackService:
                    context.read<PlaybackManagerService>().stackService,
                potSyncService: context.read<PlaybackManagerService>().potSync,
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
                demoMode: widget.demoMode,
              ),
              routes: const {},
            ),
          );
        },
      ),
    );
  }
}
