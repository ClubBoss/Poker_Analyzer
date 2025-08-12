import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_preferences_service.dart';
import '../../theme/app_colors.dart';

class FoldChipOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Offset start;
  final Offset end;
  final double scale;
  final int chipCount;

  const FoldChipOverlay({
    required this.animation,
    required this.start,
    required this.end,
    this.scale = 1.0,
  });

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final control = Offset(
              (start.dx + end.dx) / 2,
              (start.dy + end.dy) / 2 - 40 * scale,
            );
            final widgets = <Widget>[];
            for (int i = 0; i < chipCount; i++) {
              final t = (animation.value - i * 0.1).clamp(0.0, 1.0);
              final pos = _bezier(start, control, end, t);
              widgets.add(Positioned(
                left: pos.dx - 12 * scale,
                top: pos.dy - 12 * scale,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4 * scale,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
            }
            return Stack(children: widgets);
          },
        ),
      ),
    );
  }
}

class AllInLabel extends StatelessWidget {
  final double scale;
  final Animation<double> opacity;
  final Animation<double> labelScale;

  const AllInLabel({
    required this.scale,
    required this.opacity,
    required this.labelScale,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -24 * scale,
      child: FadeTransition(
        opacity: opacity,
        child: ScaleTransition(
          scale: labelScale,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Text(
              'ALL-IN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple fade-in/out "Winner" label displayed over a player zone.
class WinnerCelebration extends StatefulWidget {
  final Offset position;
  final double scale;
  final VoidCallback? onCompleted;

  const WinnerCelebration({
    Key? key,
    required this.position,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WinnerCelebration> createState() => _WinnerCelebrationState();
}

class _WinnerCelebrationState extends State<WinnerCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 30,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * widget.scale,
              vertical: 4 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 16 * widget.scale,
                  color: Colors.black,
                ),
                SizedBox(width: 4 * widget.scale),
                Text(
                  'Winner!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * widget.scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Dark overlay that fades in and out when revealing opponent cards.
class CardRevealBackdrop extends StatefulWidget {
  final Animation<double> revealAnimation;
  final VoidCallback? onCompleted;

  const CardRevealBackdrop({
    Key? key,
    required this.revealAnimation,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<CardRevealBackdrop> createState() => _CardRevealBackdropState();
}

class _CardRevealBackdropState extends State<CardRevealBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeOutController;

  @override
  void initState() {
    super.initState();
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _fadeOutController.reverse().whenComplete(() => widget.onCompleted?.call());
      }
    });
  }

  @override
  void dispose() {
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.revealAnimation, _fadeOutController]),
          builder: (context, child) {
            final opacity = widget.revealAnimation.value * _fadeOutController.value;
            return Opacity(opacity: opacity, child: child);
          },
          child: Container(color: Colors.black54),
        ),
      ),
    );
  }
}

class ChipWinOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Offset start;
  final Offset end;
  final double scale;
  final int chipCount;

  const ChipWinOverlay({
    required this.animation,
    required this.start,
    required this.end,
    this.scale = 1.0,
  });

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final control = Offset(
              (start.dx + end.dx) / 2,
              (start.dy + end.dy) / 2 - 40 * scale,
            );
            final widgets = <Widget>[];
            for (int i = 0; i < chipCount; i++) {
              final t = (animation.value - i * 0.1).clamp(0.0, 1.0);
              final pos = _bezier(start, control, end, t);
              widgets.add(Positioned(
                left: pos.dx - 12 * scale,
                top: pos.dy - 12 * scale,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4 * scale,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
            }
            return Stack(children: widgets);
          },
        ),
      ),
    );
  }
}

/// Highlights the [PlayerZoneWidget] for the given [playerName].
/// This should be called before [showWinPotAnimation] to visually
/// indicate the winner.
void showWinnerHighlight(BuildContext context, String playerName) {
  PotAnimationService().showWinnerHighlight(context, playerName);
}

/// Displays an animated glow overlay around the winning player's zone.
void showWinnerZoneOverlay(
    BuildContext context, PlayerZoneRegistry registry, String playerName) {
  final state = registry[playerName];
  final overlay = Overlay.of(context);
  if (state == null) return;
  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  showWinnerZoneHighlightOverlay(
    context: context,
    rect: rect,
    scale: state.widget.scale,
  );
}

/// Updates and reveals cards for the [PlayerZoneWidget] with the given
/// [playerName].
void revealOpponentCards(
    PlayerZoneRegistry registry, String playerName, List<CardModel> cards) {
  final state = registry[playerName];
  state?.updateCards(cards);
}

/// Sets and displays the last action label for the given player.
void setPlayerLastAction(PlayerZoneRegistry registry, String playerName,
    String? text, Color color, String action,
    [int? amount]) {
  final state = registry[playerName];
  state?.setLastAction(text, color, action, amount);
}

/// Applies a [outcome] classification to the last action label of [playerName].
void setPlayerLastActionOutcome(
    PlayerZoneRegistry registry, String playerName, ActionOutcome outcome) {
  final state = registry[playerName];
  state?.setLastActionOutcome(outcome);
}

/// Shows a showdown status label for the given player.
void setPlayerShowdownStatus(
    PlayerZoneRegistry registry, String playerName, String label) {
  final state = registry[playerName];
  state?.showShowdownLabel(label);
}

/// Clears the showdown status label for the given player.
void clearPlayerShowdownStatus(PlayerZoneRegistry registry, String playerName) {
  final state = registry[playerName];
  state?.clearShowdownLabel();
}

/// Reveals cards for multiple opponents at once. Typically called after
/// [showWinnerHighlight] and before [showWinPotAnimation].
void showOpponentCards(BuildContext context, PlayerZoneRegistry registry,
    Map<String, List<CardModel>> cardsByPlayer) {
  for (final entry in cardsByPlayer.entries) {
    revealOpponentCards(registry, entry.key, entry.value);
  }
}

/// Animates the central pot moving to the specified player's zone.
void movePotToWinner(
    BuildContext context, PlayerZoneRegistry registry, String playerName) {
  final overlay = Overlay.of(context);
  final state = registry[playerName];
  if (state == null) return;

  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;

  final end = box.localToGlobal(box.size.center(Offset.zero));
  final media = MediaQuery.of(context).size;
  final start = Offset(media.width / 2, media.height / 2);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => MovePotAnimation(
      start: start,
      end: end,
      scale: state.widget.scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// Displays a short celebratory overlay over the winning player's zone.
void showWinnerCelebration(
    BuildContext context, PlayerZoneRegistry registry, String playerName) {
  final overlay = Overlay.of(context);
  final state = registry[playerName];
  if (state == null) return;

  final box = state.context.findRenderObject() as RenderBox?;
  if (box == null) return;

  final pos = box.localToGlobal(box.size.center(Offset.zero));

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _WinnerCelebration(
      position: pos,
      scale: state.widget.scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// Runs the full winner reveal animation sequence.
///
/// Each winner will be highlighted, their cards revealed if provided, and
/// the pot will be moved to them sequentially. Winner celebrations are also
/// shown one after another when [showCelebration] is true.
Future<void> showWinnerSequence(
  BuildContext context,
  PlayerZoneRegistry registry,
  List<String> playerNames, {
  Map<String, List<CardModel>>? revealedCardsByPlayer,
  bool showCelebration = true,
}) async {
  final prefs = context.read<UserPreferencesService>();
  for (final name in playerNames) {
    // Brief delay before showing the highlight.
    await Future.delayed(const Duration(milliseconds: 500));
    showWinnerHighlight(context, name);

    // Optionally reveal the winner's cards.
    final cards = revealedCardsByPlayer?[name];
    if (cards != null && prefs.showCardReveal) {
      await Future.delayed(const Duration(milliseconds: 500));
      revealOpponentCards(registry, name, cards);
    }

    // Delay slightly longer before moving the pot.
    if (prefs.showPotAnimation) {
      await Future.delayed(const Duration(milliseconds: 700));
      movePotToWinner(context, registry, name);
    }

    if (showCelebration && prefs.showWinnerCelebration) {
      await Future.delayed(const Duration(milliseconds: 1000));
      showWinnerCelebration(context, registry, name);
  }
}
}

/// Highlights the player at [winnerIndex] and animates their stack increasing
/// by [potAmount] while chips fly from the center pot.
Future<void> triggerWinnerAnimation(
    PlayerZoneRegistry registry, int winnerIndex, int potAmount) async {
  _PlayerZoneWidgetState? state;
  for (final s in registry.values) {
    if (s.widget.playerIndex == winnerIndex) {
      state = s;
      break;
    }
  }
  if (state == null) return;
  final context = state.context;
  final lock = Provider.of<TransitionLockService?>(context, listen: false);
  lock?.lock(const Duration(milliseconds: 1600));
  state.highlightWinner();
  state.playWinChipsAnimation(potAmount);
  await state.animateStackIncrease(potAmount);
  await state.playWinnerBounce();
  state.showVictoryMessage();
  lock?.unlock();
}

/// Animates refunds flying from the center pot back to each player in [refunds].
/// Uses the same chip trail as [triggerWinnerAnimation] without highlights.
Future<void> triggerRefundAnimations(
    Map<int, int> refunds, PlayerZoneRegistry registry) async {
  await PotAnimationService().triggerRefundAnimations(refunds, registry);
}

/// Fades out the player zone when a player busts from the game.
void fadeOutBustedPlayerZone(PlayerZoneRegistry registry, String playerName) {
  final state = registry[playerName];
  state?.fadeOutZone();
}

/// Plays a refund animation for the given [playerIndex]. Chips fly from
/// [startPosition] to the player's stack.
void playRefundToPlayer(
  PlayerZoneRegistry registry,
  int playerIndex,
  int amount, {
  Offset? startPosition,
  Color color = Colors.lightGreenAccent,
  VoidCallback? onCompleted,
}) {
  _PlayerZoneWidgetState? state;
  for (final s in registry.values) {
    if (s.widget.playerIndex == playerIndex) {
      state = s;
      break;
    }
  }
  state?._playBetRefundAnimation(
    amount,
    startPosition: startPosition,
    color: color,
    onCompleted: onCompleted,
  );
}

void onShowdownResult(PlayerZoneRegistry registry, String playerName) {
  final state = registry[playerName];
  state?.onShowdownResult();
}

