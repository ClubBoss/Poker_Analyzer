import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_spot.dart';
import '../services/evaluation_executor_service.dart';
import '../services/demo_playback_controller.dart';
import '../services/player_profile_service.dart';
import '../services/player_manager_service.dart';
import '../services/all_in_players_service.dart';
import '../services/folded_players_service.dart';
import '../services/action_sync_service.dart';
import '../services/pot_history_service.dart';
import '../services/pot_sync_service.dart';
import '../services/stack_manager_service.dart';
import '../services/playback_manager_service.dart';
import '../services/board_sync_service.dart';
import '../services/transition_lock_service.dart';
import '../services/board_reveal_service.dart';
import '../services/board_manager_service.dart';
import '../services/board_editing_service.dart';
import '../services/player_editing_service.dart';
import '../services/action_history_service.dart';
import '../services/training_import_export_service.dart';
import 'poker_analyzer_screen.dart';
import '../theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class SessionReplayScreen extends StatefulWidget {
  final List<SavedHand> hands;
  final int initialIndex;
  const SessionReplayScreen({
    super.key,
    required this.hands,
    this.initialIndex = 0,
  });

  @override
  State<SessionReplayScreen> createState() => _SessionReplayScreenState();
}

class _SessionReplayScreenState extends State<SessionReplayScreen> {
  final _key = GlobalKey<PokerAnalyzerScreenState>();
  final List<TrainingSpot> _spots = [];
  final List<double> _evs = [];
  final List<double> _icms = [];
  bool _loading = true;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.hands.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _packSpot(SavedHand h) {
    final heroCards = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[
      for (final a in h.actions)
        if (a.street == 0) a,
    ];
    final stacks = <String, double>{
      for (int i = 0; i < h.numberOfPlayers; i++)
        '$i': (h.stackSizes[i] ?? 0).toDouble(),
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
        anteBb: h.anteBb,
      ),
    );
  }

  Future<void> _prepare() async {
    final exec = context.read<EvaluationExecutorService>();
    for (final h in widget.hands) {
      final pack = _packSpot(h);
      try {
        await exec.evaluateSingle(context, pack, hand: h, anteBb: h.anteBb);
      } catch (_) {}
      _evs.add(pack.heroEv ?? 0);
      _icms.add(pack.heroIcmEv ?? 0);
      _spots.add(TrainingSpot.fromSavedHand(h));
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _load();
  }

  void _load() {
    final state = _key.currentState;
    if (state == null) return;
    final controller = context.read<DemoPlaybackController>();
    final spot = _spots[_index];
    controller.playSpot(
      spot: spot,
      loadSpot: state.loadTrainingSpot,
      playAll: state.playAll,
      announceWinner: state.resolveWinner,
    );
  }

  void _next() {
    if (_index >= _spots.length - 1) return;
    setState(() => _index++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Widget _overlay() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'EV: ${_evs[_index].toStringAsFixed(2)} • ICM: ${_icms[_index].toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
      ],
      child: Builder(
        builder: (context) {
          final lockService = TransitionLockService();
          final reveal = BoardRevealService(
            lockService: lockService,
            boardSync: context.read<BoardSyncService>(),
          );
          return MultiProvider(
            providers: [
              Provider<TransitionLockService>.value(value: lockService),
              Provider<BoardRevealService>.value(value: reveal),
              ChangeNotifierProvider(
                create: (_) => BoardManagerService(
                  playerManager: context.read<PlayerManagerService>(),
                  actionSync: context.read<ActionSyncService>(),
                  playbackManager: context.read<PlaybackManagerService>(),
                  lockService: lockService,
                  boardSync: context.read<BoardSyncService>(),
                  boardReveal: reveal,
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
                  stackService: context
                      .read<PlaybackManagerService>()
                      .stackService,
                  playbackManager: context.read<PlaybackManagerService>(),
                  profile: context.read<PlayerProfileService>(),
                ),
              ),
              Provider(
                create: (_) => DemoPlaybackController(
                  playbackManager: context.read<PlaybackManagerService>(),
                  boardManager: context.read<BoardManagerService>(),
                  importExportService: const TrainingImportExportService(),
                  potSync: context.read<PlaybackManagerService>().potSync,
                ),
              ),
            ],
            child: Scaffold(
              appBar: AppBar(title: const Text('Session Replay')),
              backgroundColor: AppColors.background,
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: PokerAnalyzerScreen(
                          key: _key,
                          actionSync: context.read<ActionSyncService>(),
                          foldedPlayersService: context
                              .read<FoldedPlayersService>(),
                          allInPlayersService: context
                              .read<AllInPlayersService>(),
                          handContext: CurrentHandContextService(),
                          playbackManager: context
                              .read<PlaybackManagerService>(),
                          stackService: context
                              .read<PlaybackManagerService>()
                              .stackService,
                          potSyncService: context
                              .read<PlaybackManagerService>()
                              .potSync,
                          boardManager: context.read<BoardManagerService>(),
                          boardSync: context.read<BoardSyncService>(),
                          boardEditing: context.read<BoardEditingService>(),
                          playerEditing: context.read<PlayerEditingService>(),
                          playerManager: context.read<PlayerManagerService>(),
                          playerProfile: context.read<PlayerProfileService>(),
                          actionTagService: context
                              .read<PlayerProfileService>()
                              .actionTagService,
                          boardReveal: reveal,
                          lockService: lockService,
                          actionHistory: context.read<ActionHistoryService>(),
                          demoMode: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: _prev,
                              child: const Text('Prev'),
                            ),
                            ElevatedButton(
                              onPressed: _next,
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _overlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
