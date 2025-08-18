import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';
import '../../helpers/table_geometry_helper.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../../models/player_zone_action_entry.dart' as pz;
import '../../models/action_outcome.dart';
import '../../models/player_zone_config.dart';
import '../../services/action_sync_service.dart';
import '../../services/transition_lock_service.dart';
import '../../services/pot_animation_service.dart';
import '../../services/pot_sync_service.dart';
import '../card_selector.dart';
import '../chip_widget.dart';
import '../chip_stack_widget.dart';
import 'current_bet_label.dart';
import 'bet_size_label.dart';
import 'player_stack_value.dart';
import 'stack_bar_widget.dart';
import 'bet_flying_chips.dart';
import '../chip_stack_moving_widget.dart';
import 'chip_moving_widget.dart';
import '../bet_to_center_animation.dart';
import '../refund_chip_stack_moving_widget.dart';
import '../move_pot_animation.dart';
import '../winner_zone_highlight.dart';
import '../loss_amount_widget.dart';
import '../gain_amount_widget.dart';
import 'stack_delta_label.dart';
import 'winner_flying_chip.dart';
import 'action_tag_label.dart';
import 'player_effective_stack_label.dart';
import 'player_position_label.dart';
import 'showdown_label.dart';
import 'winner_label.dart';
import 'victory_label.dart';
import 'busted_label.dart';
import 'player_zone_animations.dart';
import 'player_zone_label_animations.dart';
import 'player_zone_overlay.dart';
import 'player_zone_action_panel.dart';
import 'bet_chip.dart';
import 'effective_stack_info.dart';
import '../active_timebar.dart';

part 'player_zone_registry.dart';
part 'player_zone_animation_controller.dart';
part 'player_zone_overlay_controller.dart';
class PlayerZoneWidget extends StatefulWidget {
  final PlayerZoneConfig config;
  final bool isActive;
  final int? timebankMs;

  /// Returns the offset of a seat around an elliptical poker table. This is
  /// based on the size of the table widget and indexes players so that index 0
  /// (hero) sits at the bottom center.
  static Offset seatPosition(
      int index, int playerCount, Size tableSize) {
    return TableGeometryHelper.positionForPlayer(
        index, playerCount, tableSize.width, tableSize.height);
  }

  const PlayerZoneWidget({Key? key, required this.config, this.isActive = false, this.timebankMs})
      : super(key: key);

  // Backward compatible getters
  String get playerName => config.playerName;
  String get street => config.street;
  String? get position => config.position;
  List<CardModel> get cards => config.cards;
  bool get isHero => config.isHero;
  bool get isFolded => config.isFolded;
  bool get isShowdownLoser => config.isShowdownLoser;
  int get currentBet => config.currentBet;
  int? get stackSize => config.stackSize;
  Map<int, int>? get stackSizes => config.stackSizes;
  int? get playerIndex => config.playerIndex;
  PlayerType get playerType => config.playerType;
  ValueChanged<PlayerType>? get onPlayerTypeChanged => config.onPlayerTypeChanged;
  bool get highlightLastAction => config.highlightLastAction;
  bool get showHint => config.showHint;
  bool get showPlayerTypeLabel => config.showPlayerTypeLabel;
  int? get remainingStack => config.remainingStack;
  String? get actionTagText => config.actionTagText;
  void Function(int, CardModel) get onCardsSelected => config.onCardsSelected;
  int get maxStackSize => config.maxStackSize;
  double get scale => config.scale;
  Set<String> get usedCards => config.usedCards;
  bool get editMode => config.editMode;
  PlayerModel get player => config.player;
  ValueChanged<int>? get onStackChanged => config.onStackChanged;
  ValueChanged<int>? get onBetChanged => config.onBetChanged;
  ValueChanged<String>? get onRevealRequest => config.onRevealRequest;

  @override
  State<PlayerZoneWidget> createState() => _PlayerZoneWidgetState();
}

class _PlayerZoneWidgetState extends State<PlayerZoneWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final PlayerZoneRegistry _registry;
  late PlayerType _playerType;
  late int _currentBet;
  late List<CardModel> _cards;
  int? _stack;
  int? _remainingStack;
  String? _actionTagText;
  late final PlayerZoneAnimations _animations;
  late final PlayerZoneAnimationController _animationController;
  late final PlayerZoneOverlayController _overlayController;
  bool get _isActive => widget.isActive || widget.config.isActive;
  bool _actionGlow = false;
  Color _actionGlowColor = Colors.transparent;
  Timer? _actionGlowTimer;
  late final AnimationController _actionGlowController;
  late final AnimationController _actionTagController;
  late final Animation<double> _actionTagOpacity;
  String? _lastActionText;
  Color _lastActionColor = Colors.black87;
  Timer? _lastActionTimer;
  int? _stackBetAmount;
  Color _stackBetColor = Colors.amber;
  Timer? _stackBetTimer;
  Timer? _gainLabelTimer;
  Timer? _lossLabelTimer;
  int? _gainLabelAmount;
  int? _lossLabelAmount;
  int? _betStackAmount;
  late final AnimationController _betStackController;
  late final Animation<double> _betStackOpacity;
  late final AnimationController _betFoldController;
  late final Animation<Offset> _betFoldOffset;
  late final Animation<double> _betFoldOpacity;
  final GlobalKey _betStackKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late TextEditingController _stackController;
  late TextEditingController _betController;
  // Controls the fold animation that hides a player's cards.
  late final AnimationController _foldController;
  // Offset for sliding cards downward as they fold.
  late final Animation<Offset> _foldOffset;
  // Opacity animation used to fade cards out when folding.
  late final Animation<double> _foldOpacity;
  bool _showCards = true;
  bool _hoverAction = false;
  String? _showdownLabel;
  Timer? _showdownLabelTimer;
  String? _finalStackText;
  Timer? _finalStackTimer;
  Timer? _hideCardsTimer;
  late final AnimationController _revealController;
  late final Animation<double> _revealOpacity;
  late final Animation<double> _revealScale;
  late final AnimationController _revealEyeController;
  Timer? _revealEyeTimer;
  final GlobalKey<TooltipState> _revealTooltipKey = GlobalKey<TooltipState>();
  bool _hasShownRevealHint = false;
  late final AnimationController _stackWinController;
  late final Animation<double> _stackWinScale;
  late final Animation<double> _stackWinOpacity;
  late final Animation<double> _stackWinGlow;
  late final AnimationController _chipWinController;
  late final AnimationController _foldChipController;
  late final AnimationController _showdownLossController;
  bool _showBusted = false;
  Timer? _bustedTimer;
  late final AnimationController _bustedController;
  late final Animation<double> _bustedOpacity;
  late final Animation<Offset> _bustedOffset;
  Timer? _allInTimer;
  late final AnimationController _zoneFadeController;
  late final Animation<double> _zoneFadeOpacity;
  late final Animation<Offset> _zoneFadeOffset;
  bool _zoneFaded = false;
  bool _isBusted = false;
  bool _showAllIn = false;
  late final AnimationController _allInController;
  late final Animation<double> _allInOpacity;
  late final Animation<Offset> _allInOffset;
  late final Animation<double> _allInScale;
  bool _wasAllIn = false;
  bool _showWinnerLabel = false;
  late final PlayerZoneLabelAnimations _labelAnimations;
  bool _showVictory = false;

  late final AnimationController _stackBarController;
  late Animation<double> _stackBarProgressAnimation;
  late Animation<double> _stackBarGlow;
  double _stackBarProgress = 0.0;
  late final AnimationController _stackBarFadeController;
  late final Animation<double> _stackBarFade;

  @override
  void initState() {
    super.initState();
    _playerType = widget.playerType;
    _currentBet = widget.player.bet;
    _cards = List<CardModel>.from(widget.cards);
    _actionTagText = widget.actionTagText;
    _stack = widget.player.stack;
    if (widget.stackSize != null) {
      _stack = widget.stackSize;
    } else if (widget.stackSizes != null && widget.playerIndex != null) {
      _stack = widget.stackSizes![widget.playerIndex!];
    }
    if (widget.currentBet != 0) {
      _currentBet = widget.currentBet;
    }
    _remainingStack = widget.remainingStack;
    _registry = Provider.of<PlayerZoneRegistry>(context, listen: false);
    _registry.register(widget.playerName, this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
    if (_isActive) {
      _controller.repeat(reverse: true);
    }
    _stackController = TextEditingController(text: _stack?.toString() ?? '');
    _betController = TextEditingController(text: '$_currentBet');
    _foldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _showCards = false);
        }
      });
    _foldOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 0.6))
        .animate(CurvedAnimation(parent: _foldController, curve: Curves.easeIn));
    _foldOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _foldController, curve: Curves.easeIn));
    if (widget.isFolded) {
      _showCards = false;
    }
    _labelAnimations =
        PlayerZoneLabelAnimations(vsync: this, isHero: widget.isHero);
    _labelAnimations.winnerLabelController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showWinnerLabel = false);
      }
    });
    _labelAnimations.victoryController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showVictory = false);
      }
    });
    _actionGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _actionTagController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _actionTagOpacity = CurvedAnimation(parent: _actionTagController, curve: Curves.easeIn);
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _revealOpacity =
        CurvedAnimation(parent: _revealController, curve: Curves.easeIn);
    _revealScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _revealController, curve: Curves.easeOut));
    _revealEyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0.0,
    );
    _stackWinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _chipWinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _foldChipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _showdownLossController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _stackWinScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_stackWinController);
    _stackWinOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_stackWinController);
    _stackWinGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_stackWinController);
    _animations = PlayerZoneAnimations(vsync: this);

    _bustedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bustedOpacity =
        CurvedAnimation(parent: _bustedController, curve: Curves.easeIn);
    _bustedOffset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _bustedController, curve: Curves.easeOut));
    _zoneFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _zoneFadeOpacity =
        Tween<double>(begin: 1.0, end: 0.0).animate(_zoneFadeController);
    _zoneFadeOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.2))
        .animate(CurvedAnimation(parent: _zoneFadeController, curve: Curves.easeIn));

    _allInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _allInOpacity =
        CurvedAnimation(parent: _allInController, curve: Curves.easeIn);
    _allInOffset = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _allInController, curve: Curves.easeOut));
    _allInScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _allInController, curve: Curves.easeOut));

    _stackBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _stackBarGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _stackBarController, curve: Curves.easeOut));
    _stackBarProgress = (_stack ?? 0) / widget.maxStackSize;
    _stackBarProgressAnimation = AlwaysStoppedAnimation<double>(_stackBarProgress);

    _stackBarFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: (!widget.isHero && widget.isFolded) ? 0.0 : 1.0,
    );
    _stackBarFade = CurvedAnimation(parent: _stackBarFadeController, curve: Curves.easeInOut);

    _betStackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _betStackOpacity = CurvedAnimation(parent: _betStackController, curve: Curves.easeInOut);
    _betFoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _betFoldOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.3))
        .animate(CurvedAnimation(parent: _betFoldController, curve: Curves.easeIn));
    _betFoldOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _betFoldController, curve: Curves.easeIn));
    if (!widget.isHero && _currentBet > 0) {
      _betStackAmount = _currentBet;
      _betStackController.value = 1.0;
    }

    if (!widget.isHero && !widget.isFolded && _remainingStack == 0) {
      _wasAllIn = true;
      _showAllInLabel();
    }
    _animationController = PlayerZoneAnimationController(this);
    _overlayController = PlayerZoneOverlayController(this);
  }

  @override
  void didUpdateWidget(covariant PlayerZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerName != oldWidget.playerName) {
      _registry.unregister(oldWidget.playerName);
      _registry.register(widget.playerName, this);
    }
    final bool wasActive = oldWidget.isActive || oldWidget.config.isActive;
    final bool isActive = _isActive;
    if (isActive && !wasActive) {
      _controller
        ..reset()
        ..repeat(reverse: true);
    } else if (!isActive && wasActive) {
      _controller.stop();
      _controller.reset();
    }
    if (widget.playerType != oldWidget.playerType) {
      _playerType = widget.playerType;
    }
    if (widget.cards != oldWidget.cards) {
      final becameVisible = oldWidget.cards.isEmpty && widget.cards.isNotEmpty;
      _cards = List<CardModel>.from(widget.cards);
      if (!widget.isHero && becameVisible) {
        _revealController.forward(from: 0.0);
        _showCardRevealOverlay();
      }
    }
    if (widget.isFolded && !oldWidget.isFolded) {
      // When a player folds, slide their cards down and fade them out. Skip
      // the animation for the hero so the cards disappear immediately.
      if (widget.isHero) {
        setState(() => _showCards = false);
      } else {
        setState(() => _showCards = true);
        _foldController.forward(from: 0.0);
      }
      if (!widget.isHero) {
        _stackBarFadeController.reverse();
        if (_betStackAmount != null) {
          _overlayController.startFoldChipAnimation();
          _betFoldController.forward(from: 0.0).whenComplete(() {
            if (mounted) setState(() => _betStackAmount = null);
          });
        }
      }
    } else if (!widget.isFolded && oldWidget.isFolded) {
      // Reset the fold animation when cards are shown again for non-hero players.
      if (!widget.isHero) {
        _foldController.reset();
      }
      setState(() => _showCards = true);
      if (!widget.isHero) {
        _stackBarFadeController.forward();
        _betFoldController.reset();
      }
    }
    if (!widget.isHero &&
        !widget.isFolded &&
        widget.isShowdownLoser &&
        !oldWidget.isShowdownLoser) {
      _overlayController.startShowdownLossAnimation();
    }
    if (widget.player.bet != oldWidget.player.bet ||
        widget.currentBet != oldWidget.currentBet) {
      _currentBet = widget.player.bet;
      if (widget.currentBet != oldWidget.currentBet) {
        final delta = widget.currentBet - oldWidget.currentBet;
        if (delta > 0) {
          _overlayController.playBetAnimation(delta);
        } else if (delta < 0) {
          Offset? start;
          final betBox =
              _betStackKey.currentContext?.findRenderObject() as RenderBox?;
          if (betBox != null) {
            start = betBox.localToGlobal(
                Offset(betBox.size.width / 2, betBox.size.height / 2));
          }
          _overlayController.playBetRefundAnimation(
            -delta,
            startPosition: start,
            color: Colors.amber,
          );
          _betStackController.reverse().whenComplete(() {
            if (mounted && _betStackAmount != null) {
              setState(() => _betStackAmount = null);
            }
          });
        }
      }
      _betController.text = '$_currentBet';
      if (!widget.isHero) {
        if (_currentBet > 0) {
          setState(() => _betStackAmount = _currentBet);
          _betStackController.forward();
        } else {
          _betStackController.reverse().whenComplete(() {
            if (mounted) setState(() => _betStackAmount = null);
          });
        }
      }
    }
    if (widget.actionTagText != oldWidget.actionTagText) {
      _actionTagText = widget.actionTagText;
    }
    final int? oldStack = oldWidget.stackSize ??
        (oldWidget.stackSizes != null && oldWidget.playerIndex != null
            ? oldWidget.stackSizes![oldWidget.playerIndex!]
            : null);
    final int? newStack = widget.stackSize ??
        (widget.stackSizes != null && widget.playerIndex != null
            ? widget.stackSizes![widget.playerIndex!]
            : widget.player.stack);
    if (newStack != oldStack) {
      if (oldStack != null && newStack != null && newStack > oldStack) {
        animateStackIncrease(newStack - oldStack);
      } else {
        setState(() {
          _stack = newStack;
          _stackBarProgress = (_stack ?? 0) / widget.maxStackSize;
          _stackBarProgressAnimation =
              AlwaysStoppedAnimation<double>(_stackBarProgress);
        });
      }
      _stackController.text = newStack?.toString() ?? '';
    }
    if (widget.remainingStack != oldWidget.remainingStack) {
      setState(() => _remainingStack = widget.remainingStack);
      if ((_remainingStack ?? -1) == 0) {
        _wasAllIn = true;
      }
      if (!widget.isHero && !widget.isFolded) {
        if ((_remainingStack ?? -1) == 0 && (oldWidget.remainingStack ?? -1) != 0) {
          _showAllInLabel();
        } else if ((_remainingStack ?? -1) != 0 && (oldWidget.remainingStack ?? -1) == 0) {
          _allInController.reverse().whenComplete(() {
            if (mounted) setState(() => _showAllIn = false);
          });
        }
      }
    }
    if (widget.isFolded && !oldWidget.isFolded && _showAllIn) {
      _allInController.reverse().whenComplete(() {
        if (mounted) setState(() => _showAllIn = false);
      });
    }
  }

  /// Updates the player's bet value.
  void updateBet(int bet) {
    setState(() => _currentBet = bet);
  }

  /// Updates the player's visible cards.
  void updateCards(List<CardModel> cards) {
    final wasHidden = _cards.isEmpty;
    setState(() => _cards = List<CardModel>.from(cards));
    if (!widget.isHero && wasHidden && cards.isNotEmpty) {
      _showCardRevealOverlay();
      _revealController.forward(from: 0.0);
    }
  }

  void highlightWinner() => _animationController.highlightWinner();

  void clearWinnerHighlight() =>
      _animationController.clearWinnerHighlight();

  void showRefundGlow() => _animationController.showRefundGlow();

  Future<void> playWinnerBounce() =>
      _animationController.playWinnerBounce();


  /// Returns the display color for a last action label.
  Color _lastActionColorFor(String action) {
    switch (action.toLowerCase()) {
      case 'push':
      case 'all-in':
        return Colors.red;
      case 'call':
        return Colors.blue;
      case 'check':
        return Colors.grey;
      case 'raise':
        return Colors.orange;
      case 'fold':
        return Colors.grey.shade800;
      default:
        return Colors.black87;
    }
  }

  void setLastAction(String? text, Color color, String action, [int? amount]) {
    _lastActionTimer?.cancel();
    _actionGlowTimer?.cancel();
    _actionGlowController
      ..stop()
      ..value = 0.0;
    _actionTagController
      ..stop()
      ..value = 0.0;
    if (text == null) {
      _overlayController.clearActionLabel();
      setState(() {
        _lastActionText = null;
        _actionGlow = false;
        _actionGlowColor = Colors.transparent;
      });
      return;
    }
    final labelColor = _lastActionColorFor(action);
    setState(() {
      _lastActionText = text;
      _lastActionColor = labelColor;
      _actionGlow = true;
      _actionGlowColor = labelColor;
    });
    _overlayController.showActionLabel(text, labelColor);
    _actionGlowController.forward(from: 0.0);
    _actionTagController.forward(from: 0.0);
    _lastActionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _actionTagController.reverse().whenComplete(() {
        if (mounted) setState(() => _lastActionText = null);
      });
      _actionGlowController.reverse();
    });
    _actionGlowTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _actionGlow = false);
      }
    });
    if (amount != null) {
      _overlayController.showBetOverlay(amount, color);
      if (action == 'bet' || action == 'raise' || action == 'call') {
        _overlayController.playBetChipsToCenter(amount, color: color);
      }
      if (action == 'bet' || action == 'raise') {
        _showStackBetDisplay(amount, color);
      }
    }
  }

  void setLastActionOutcome(ActionOutcome outcome) {
    Color color;
    int? lostAmount;
    int? gainAmount;
    switch (outcome) {
      case ActionOutcome.win:
        color = Colors.green;
        if (_stack != null && _stack! > widget.maxStackSize) {
          gainAmount = _stack! - widget.maxStackSize;
        }
        break;
      case ActionOutcome.lose:
        color = Colors.red;
        if (_stack != null && widget.maxStackSize > _stack!) {
          lostAmount = widget.maxStackSize - _stack!;
        }
        break;
      case ActionOutcome.neutral:
      default:
        color = Colors.white;
    }
    if (mounted) {
      setState(() => _lastActionColor = color);
      _showFinalStackLabel();
      _showBustedLabel();
      if (lostAmount != null && lostAmount > 0) {
        _overlayController.showLossAmount(lostAmount);
        _showStackLossLabel(lostAmount);
      }
      if (gainAmount != null && gainAmount > 0) {
        _overlayController.showGainAmount(gainAmount);
      }
    }
  }

  void showShowdownLabel(String text) {
    if (widget.isHero) return;
    if (text == 'W') {
      _stackWinController.forward(from: 0.0);
    }
    _showdownLabelTimer?.cancel();
    setState(() => _showdownLabel = text);
    _labelAnimations.showdownLabelController.forward(from: 0.0);
    _showdownLabelTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _labelAnimations.showdownLabelController.reverse().whenComplete(() {
        if (mounted) {
          setState(() => _showdownLabel = null);
        }
      });
    });
  }

  void clearShowdownLabel() {
    _showdownLabelTimer?.cancel();
    if (_showdownLabel != null) {
      setState(() => _showdownLabel = null);
      _labelAnimations.showdownLabelController.reset();
    }
  }

  void _showCardRevealOverlay() {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CardRevealBackdrop(
        revealAnimation: _revealOpacity,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _playBetRefundAnimation(
    int amount, {
    Offset? startPosition,
    Color color = Colors.lightGreenAccent,
    VoidCallback? onCompleted,
  }) =>
      _overlayController.playBetRefundAnimation(amount,
          startPosition: startPosition, color: color, onCompleted: onCompleted);

  /// Animates this player's bet flying toward the center pot.
  void playBetChipsToCenter(int amount, {Color color = Colors.amber}) =>
      _overlayController.playBetChipsToCenter(amount, color: color);

  void showBetOverlay(int amount, Color color) =>
      _overlayController.showBetOverlay(amount, color);

  void showRefundMessage(int amount) =>
      _overlayController.showRefundMessage(amount);

  void _showStackBetDisplay(int amount, Color color) {
    _stackBetTimer?.cancel();
    setState(() {
      _stackBetAmount = amount;
      _stackBetColor = color;
    });
    _stackBetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _stackBetAmount = null);
      }
    });
  }

  void _showStackGainLabel(int amount) {
    if (widget.isHero || amount <= 0) return;
    _gainLabelTimer?.cancel();
    setState(() => _gainLabelAmount = amount);
    _gainLabelTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _gainLabelAmount = null);
    });
  }

  void _showStackLossLabel(int amount) {
    if (widget.isHero || amount <= 0) return;
    _lossLabelTimer?.cancel();
    setState(() => _lossLabelAmount = amount);
    _lossLabelTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _lossLabelAmount = null);
    });
  }

  void _showFinalStackLabel() {
    if (widget.isHero) return;
    _finalStackTimer?.cancel();
    _hideCardsTimer?.cancel();
    setFinalStackText('Final: ${_stack ?? 0} BB');
    if (_betStackAmount != null) {
      _betStackController.reverse().whenComplete(() {
        if (mounted) setState(() => _betStackAmount = null);
      });
    }
    _hideCardsTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      setState(() => _showCards = false);
    });
  }

  void setFinalStackText(String text) {
    if (widget.isHero) return;
    _finalStackTimer?.cancel();
    setState(() => _finalStackText = text);
    _labelAnimations.finalStackController.forward(from: 0.0);
    _finalStackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _labelAnimations.finalStackController.reverse().whenComplete(() {
        if (mounted) setState(() => _finalStackText = null);
      });
    });
  }

  void _showWinnerLabelAnimated() {
    if (widget.isHero) return;
    setState(() => _showWinnerLabel = true);
    _labelAnimations.winnerLabelController.forward(from: 0.0);
  }

  void showVictoryMessage() {
    setState(() => _showVictory = true);
    _labelAnimations.victoryController.forward(from: 0.0);
  }

  void _showAllInLabel() {
    if (widget.isHero) return;
    _allInTimer?.cancel();
    setState(() => _showAllIn = true);
    _allInController.forward(from: 0.0);
    _allInTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _allInController.reverse().whenComplete(() {
        if (mounted) setState(() => _showAllIn = false);
      });
    });
  }

  void _showBustedLabel() {
    if (widget.isHero || _remainingStack != 0) return;
    _bustedTimer?.cancel();
    setState(() {
      _showBusted = true;
      _showAllIn = false;
    });
    _bustedController.forward(from: 0.0);
    _bustedTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _bustedController.reverse().whenComplete(() {
        if (mounted) setState(() => _showBusted = false);
      });
    });
  }

  void fadeOutZone() {
    if (widget.isHero || _zoneFaded) return;
    _zoneFaded = true;
    void startFade() {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _zoneFadeController.forward().whenComplete(() {
          if (mounted) setState(() => _isBusted = true);
        });
      });
    }

    if (_bustedController.status == AnimationStatus.dismissed) {
      startFade();
    } else {
      late final AnimationStatusListener listener;
      listener = (status) {
        if (status == AnimationStatus.dismissed) {
          _bustedController.removeStatusListener(listener);
          startFade();
        }
      };
      _bustedController.addStatusListener(listener);
    }
  }

  void _showRevealEye() {
    _revealEyeTimer?.cancel();
    _revealEyeController.forward();
    if (!_hasShownRevealHint) {
      _revealTooltipKey.currentState?.ensureTooltipVisible();
      _hasShownRevealHint = true;
    }
  }

  void _scheduleHideRevealEye() {
    _revealEyeTimer?.cancel();
    _revealEyeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _revealEyeController.reverse();
    });
  }

  /// Animates chips flying from the center pot to this player.
  void playWinChipsAnimation(int amount) =>
      _overlayController.playWinChipsAnimation(amount);

  /// Smoothly increases this player's stack by [amount].
  Future<void> animateStackIncrease(int amount) async {
    if (_stack == null) return;
    _showStackGainLabel(amount);
    final oldStack = _stack!;
    final newStack = _stack! + amount;

    _stackBarProgressAnimation = Tween<double>(
      begin: _stackBarProgress,
      end: (newStack / widget.maxStackSize).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _stackBarController, curve: Curves.easeOut))
      ..addListener(() {
        if (mounted) {
          setState(() => _stackBarProgress = _stackBarProgressAnimation.value);
        }
      });

    _stackBarController.forward(from: 0.0);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final animation = IntTween(begin: oldStack, end: newStack).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    )..addListener(() {
        if (mounted) setState(() => _stack = animation.value);
      });
    await controller.forward();
    controller.dispose();
  }

  Future<void> _editStack() async {
    final controller = TextEditingController(text: _stack?.toString() ?? '');
    int? value = _stack;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          title: const Text(
            'Edit Stack',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Enter stack in BB',
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            onChanged: (text) => setState(() => value = int.tryParse(text)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  value != null && value! > 0 ? () => Navigator.pop(context, value) : null,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result > 0) {
      setState(() => _stack = result);
    }
  }

  void onShowdownResult() {
    if (!widget.isHero && !widget.isFolded && widget.isShowdownLoser == true) {
      _overlayController.startShowdownLossAnimation();
    }
  }

  Widget _betIndicator(TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * widget.scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🪙', style: TextStyle(fontSize: 12 * widget.scale)),
          SizedBox(width: 4 * widget.scale),
          Text('$_currentBet', style: style),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _registry.unregister(widget.playerName);
    _lastActionTimer?.cancel();
    _actionGlowTimer?.cancel();
    _stackBetTimer?.cancel();
    _gainLabelTimer?.cancel();
    _lossLabelTimer?.cancel();
    _showdownLabelTimer?.cancel();
    _finalStackTimer?.cancel();
    _hideCardsTimer?.cancel();
    _bustedTimer?.cancel();
    _allInTimer?.cancel();
    _revealEyeTimer?.cancel();
    _animationController.dispose();
    _overlayController.dispose();
    _stackController.dispose();
    _betController.dispose();
    _controller.dispose();
    _bounceController.dispose();
    _foldController.dispose();
    _labelAnimations.dispose();
    _revealController.dispose();
    _revealEyeController.dispose();
    _animations.dispose();
    _actionGlowController.dispose();
    _actionTagController.dispose();
    _chipWinController.dispose();
    _foldChipController.dispose();
    _showdownLossController.dispose();
    _stackWinController.dispose();
    _stackBarController.dispose();
    _stackBarFadeController.dispose();
    _betFoldController.dispose();
    _betStackController.dispose();
    _bustedController.dispose();
    _zoneFadeController.dispose();
    _allInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final platform = Theme.of(context).platform;
    final bool isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final int? stack = _stack;
    final int? remaining = _remainingStack;
    final nameStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14 * widget.scale,
    );
    final stackStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10 * widget.scale,
      fontWeight: FontWeight.w500,
    );
    final betStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12 * widget.scale,
      fontWeight: FontWeight.w600,
    );
    final tagStyle = TextStyle(color: Colors.white, fontSize: 12 * widget.scale);

    final label = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100 * widget.scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * widget.scale, vertical: 4 * widget.scale),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12 * widget.scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.playerName,
                  style: nameStyle,
                ),
                GestureDetector(
                  onLongPressStart: (d) => _showPlayerTypeMenu(d.globalPosition),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Text(
                      _playerTypeIcon(_playerType),
                      style: TextStyle(fontSize: 14 * widget.scale),
                    ),
                  ),
                ),
                if (widget.isHero)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4 * widget.scale, vertical: 2 * widget.scale),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6 * widget.scale),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            blurRadius: 4 * widget.scale,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12 * widget.scale,
                          ),
                          SizedBox(width: 2 * widget.scale),
                          Text(
                            'Hero',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10 * widget.scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.isFolded && remaining != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  'Осталось: $remaining',
                  style: stackStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            if (widget.position != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: PlayerPositionLabel(
                  position: widget.position,
                  scale: widget.scale,
                  isDark: isDark,
                ),
              ),
            if (stack != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  '$stack BB',
                  style: stackStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 2.0 * widget.scale),
              child: EffectiveStackInfo(
                street: widget.street,
                style: stackStyle,
              ),
            ),
          ],
        ),
      ),
    );

    final labelWithIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        label,
        Positioned(
          top: -4 * widget.scale,
          right: -4 * widget.scale,
          child: AnimatedOpacity(
            opacity: widget.showHint ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: widget.showHint ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: Tooltip(
                message: 'Нажмите, чтобы ввести действие',
                child: Icon(
                  Icons.edit,
                  size: 16 * widget.scale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLeftSide(widget.position))
          BetChip(currentBet: _currentBet, scale: widget.scale, style: betStyle),
        labelWithIcon,
        if (!_isLeftSide(widget.position))
          BetChip(currentBet: _currentBet, scale: widget.scale, style: betStyle),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelRow,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: (!widget.isFolded && _currentBet > 0)
              ? Padding(
                  padding: EdgeInsets.only(top: 4 * widget.scale),
                  child: ChipWidget(amount: _currentBet, scale: widget.scale),
                )
              : SizedBox(height: 4 * widget.scale),
        ),
        SizedBox(height: 4 * widget.scale),
        if (_showdownLabel != null && !widget.isHero)
          ShowdownLabel(
            text: _showdownLabel!,
            scale: widget.scale,
            opacity: _labelAnimations.showdownLabelOpacity,
          ),
        Builder(
          builder: (_) {
            Widget row = Opacity(
              opacity: widget.isFolded ? 0.4 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentBet > 0 && _isLeftSide(widget.position))
                    _betIndicator(betStyle),
                  ...List.generate(2, (index) {
                  final card = index < _cards.length ? _cards[index] : null;
                  final isRed = card?.suit == '♥' || card?.suit == '♦';

                  final Widget cardWidget = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isHero
                      ? () async {
                          final disabled = Set<String>.from(widget.usedCards);
                          if (card != null) disabled.remove('${card.rank}${card.suit}');
                          final selected = await showCardSelector(
                            context,
                            disabledCards: disabled,
                          );
                          if (selected != null) {
                            widget.onCardsSelected(index, selected);
                          }
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 36 * widget.scale,
                    height: 52 * widget.scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: card == null ? 0.3 : 1),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 3,
                          offset: const Offset(1, 2),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: card != null
                          ? Text(
                              '${card.rank}${card.suit}',
                              key: ValueKey('${card.rank}${card.suit}$index'),
                              style: TextStyle(
                                color: isRed ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18 * widget.scale,
                              ),
                            )
                          : widget.isHero
                              ? const Icon(Icons.add,
                                  color: Colors.grey, key: ValueKey('add'))
                              : Image.asset(
                                  'assets/cards/card_back.png',
                                  key: const ValueKey('back'),
                                  fit: BoxFit.cover,
                                ),
                    ),
                  ),
                );

                if (!_showCards && !_foldController.isAnimating) {
                  return const SizedBox.shrink();
                }

                return SlideTransition(
                  position: _foldOffset,
                  child: FadeTransition(
                    opacity: _foldOpacity,
                    child: cardWidget,
                  ),
                );
              }),
                  if (_currentBet > 0 && !_isLeftSide(widget.position))
                    _betIndicator(betStyle),
                ],
              ),
            );
            row = AnimatedBuilder(
              animation: _animations.winnerHighlightController,
              builder: (_, child) {
                final glow = _animations.winnerHighlightGlow.value;
                return Container(
                  decoration: glow > 0
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(8 * widget.scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellowAccent.withValues(alpha: glow),
                              blurRadius: 12 * glow * widget.scale,
                              spreadRadius: 2 * glow * widget.scale,
                            ),
                          ],
                        )
                      : null,
                  child: child,
                );
              },
              child: row,
            );
            if (!widget.isHero) {
              row = FadeTransition(
                opacity: _revealOpacity,
                child: ScaleTransition(
                  scale: _revealScale,
                  child: row,
                ),
              );
            }
            return row;
          },
        ),
      ),
        if (widget.editMode) {
          Padding(
            padding: EdgeInsets.only(top: 4 * widget.scale),
            child: Column(
              children: [
                SizedBox(
                  width: 60 * widget.scale,
                  child: TextField(
                    controller: _stackController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Stack',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 0;
                      widget.player.stack = val;
                      widget.onStackChanged?.call(val);
                      setState(() => _stack = val);
                    },
                  ),
                ),
                SizedBox(height: 4 * widget.scale),
                SizedBox(
                  width: 60 * widget.scale,
                  child: TextField(
                    controller: _betController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Bet',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 0;
                      widget.player.bet = val;
                      widget.onBetChanged?.call(val);
                      setState(() => _currentBet = val);
                    },
                  ),
                ),
              ],
            ),
          )
        
        } else {
          GestureDetector(
            onLongPress: _editStack,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _stackWinController,
                  builder: (_, child) {
                    final glow = _stackWinGlow.value;
                    return Container(
                      decoration: glow > 0
                          ? BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(8 * widget.scale),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.greenAccent.withValues(alpha: glow),
                                  blurRadius: 16 * glow * widget.scale,
                                  spreadRadius: 4 * glow * widget.scale,
                                ),
                              ],
                            )
                          : null,
                      child: child,
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _animations.allInWinGlowController,
                    builder: (_, child) {
                      final glow = _animations.allInWinGlow.value;
                      return Container(
                        decoration: glow > 0
                            ? BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(8 * widget.scale),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.lightGreenAccent
                                        .withValues(alpha: glow),
                                    blurRadius: 16 * glow * widget.scale,
                                    spreadRadius: 4 * glow * widget.scale,
                                  ),
                                ],
                              )
                            : null,
                        child: child,
                      );
                    },
                    child: ScaleTransition(
                      scale: _stackWinScale,
                      child: FadeTransition(
                        opacity: _stackWinOpacity,
                        child: PlayerStackValue(
                          key: _stackKey,
                          stack: stack ?? 0,
                          scale: widget.scale,
                          isBust: remaining != null && remaining <= 0,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_finalStackText != null && !widget.isHero)
                  Positioned(
                    top: -24 * widget.scale,
                    child: SlideTransition(
                      position: _labelAnimations.finalStackOffset,
                      child: FadeTransition(
                        opacity: _labelAnimations.finalStackOpacity,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6 * widget.scale,
                              vertical: 2 * widget.scale),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius:
                                BorderRadius.circular(8 * widget.scale),
                          ),
                          child: Text(
                            _finalStackText!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10 * widget.scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_showWinnerLabel && !widget.isHero)
                  WinnerLabel(
                    scale: widget.scale,
                    opacity: _labelAnimations.winnerLabelOpacity,
                    scaleAnimation: _labelAnimations.winnerLabelScale,
                  ),
                if (_showVictory)
                  VictoryLabel(
                    scale: widget.scale,
                    opacity: _labelAnimations.victoryOpacity,
                  ),
                if (_gainLabelAmount != null && !widget.isHero)
                  Positioned(
                    top: -14 * widget.scale,
                    child: StackDeltaLabel(
                      deltaAmount: _gainLabelAmount!,
                      isGain: true,
                      offsetUp: true,
                      labelColor: Colors.lightGreenAccent,
                      scale: widget.scale,
                    ),
                  ),
                if (_lossLabelAmount != null && !widget.isHero)
                  Positioned(
                    bottom: -14 * widget.scale,
                    child: StackDeltaLabel(
                      deltaAmount: _lossLabelAmount!,
                      isGain: false,
                      offsetUp: false,
                      labelColor: Colors.redAccent,
                      scale: widget.scale,
                    ),
                  ),
                if (_showBusted && !widget.isHero)
                  BustedLabel(
                    scale: widget.scale,
                    offset: _bustedOffset,
                    opacity: _bustedOpacity,
                  ),
                if (_showAllIn && !widget.isHero)
                  AllInLabel(
                    scale: widget.scale,
                    opacity: _allInOpacity,
                    labelScale: _allInScale,
                  ),
              ],
            ),
          )
        },
        PlayerEffectiveStackLabel(
          stack: context.watch<PotSyncService>()
                  .effectiveStacks[widget.street],
          scale: widget.scale,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _stackBetAmount != null
              ? Padding(
                  padding: EdgeInsets.only(top: 4 * widget.scale),
                  child: BetSizeLabel(
                    key: ValueKey(_stackBetAmount),
                    amount: _stackBetAmount!,
                    color: _stackBetColor,
                    scale: widget.scale,
                  ),
                )
              : SizedBox(height: 4 * widget.scale),
        ),
        if (widget.showPlayerTypeLabel) {
          AnimatedOpacity(
            opacity: widget.showPlayerTypeLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.only(top: 2.0 * widget.scale),
              child: Text(
                _playerTypeLabel(_playerType),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10 * widget.scale,
                ),
              ),
            ),
          )
        },
        FadeTransition(
          opacity: _stackBarFade,
          child: StackBarWidget(
            stack: stack,
            maxStack: widget.maxStackSize,
            scale: widget.scale,
            progressAnimation: _stackBarProgressAnimation,
            glowAnimation: _stackBarGlow,
          ),
        ),
        CurrentBetLabel(bet: _currentBet, scale: widget.scale),
        if (_actionTagText != null) {
          Padding(
            padding: EdgeInsets.only(top: 4.0 * widget.scale),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * widget.scale, vertical: 2 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10 * widget.scale),
              ),
              child: Text(
                _actionTagText!,
                style: tagStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        },
      ],
    )

    final panel = PlayerZoneActionPanel(
      child: column,
      betStackAmount: _betStackAmount,
      isHero: widget.isHero,
      isLeftSide: _isLeftSide(widget.position),
      betFoldOffset: _betFoldOffset,
      betFoldOpacity: _betFoldOpacity,
      betStackOpacity: _betStackOpacity,
      betStackKey: _betStackKey,
      lastActionText: _lastActionText,
      actionTagOpacity: _actionTagOpacity,
      lastActionColor: _lastActionColor,
      heroLabelOpacity: _labelAnimations.heroLabelOpacity,
      heroLabelScale: _labelAnimations.heroLabelScale,
      scale: widget.scale,
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        panel,
        if (!widget.isHero && !widget.isFolded && widget.onRevealRequest != null && widget.cards.length == 2)
          Positioned(
            top: -8 * widget.scale,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _revealEyeController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8 * widget.scale),
                ),
                child: Tooltip(
                  key: _revealTooltipKey,
                  triggerMode: TooltipTriggerMode.manual,
                  showDuration: const Duration(seconds: 2),
                  preferBelow: false,
                  message: 'Нажмите, чтобы раскрыть карты',
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 14 * widget.scale,
                    splashRadius: 16 * widget.scale,
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                    onPressed: () =>
                        widget.onRevealRequest?.call(widget.playerName),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: -8 * widget.scale,
          right: -8 * widget.scale,
          child: AnimatedOpacity(
            opacity: isMobile || _hoverAction ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8 * widget.scale),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 14 * widget.scale,
                splashRadius: 16 * widget.scale,
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _onAddAction,
              ),
            ),
          ),
        ),
      ],
    );

    Widget result = content;

    if (widget.isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.4, child: result),
        ),
      );
    }

    result = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bool highlight = widget.highlightLastAction;
        final double width = widget.highlightLastAction ? 2 + _controller.value * 2 : 3;
        final double blur = widget.highlightLastAction ? 8 + _controller.value * 4 : 8;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(2 * widget.scale),
          decoration: highlight
              ? BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: width),
                  borderRadius: BorderRadius.circular(12 * widget.scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                      blurRadius: blur,
                    )
                  ],
                )
              : null,
          child: child,
        );
      },
      child: result,
    );

    if (widget.isHero) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * widget.scale),
          border: Border.all(color: AppColors.accent, width: 2 * widget.scale),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.7),
              blurRadius: 12 * widget.scale,
              spreadRadius: 2 * widget.scale,
            ),
          ],
        ),
        child: result,
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: (_animationController.refundGlow && !_animationController.winnerHighlight)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            )
          : null,
      child: result,
    );

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: _actionGlow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: _actionGlowColor.withValues(alpha: 0.7),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            )
          : null,
      child: result,
    );

    result = AnimatedBuilder(
      animation: _animations.winnerGlowController,
      builder: (_, child) {
        final glow = _animations.winnerGlowOpacity.value;
        final scale = _animations.winnerGlowScale.value;
        if (!_animationController.winnerHighlight && glow == 0.0) return child!;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: glow > 0.0
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: glow),
                        blurRadius: 24 * glow * widget.scale,
                        spreadRadius: 4 * glow * widget.scale,
                      ),
                    ],
                  )
                : null,
            child: child,
          ),
        );
      },
      child: result,
    );

    result = ScaleTransition(
      scale: _bounceAnimation,
      child: result,
    );

    result = SlideTransition(
      position: _zoneFadeOffset,
      child: FadeTransition(
        opacity: _zoneFadeOpacity,
        child: result,
      ),
    );

    Widget zone = MouseRegion(
      onEnter: (_) {
        if (!isMobile) {
          setState(() => _hoverAction = true);
          _showRevealEye();
        }
      },
      onExit: (_) {
        if (!isMobile) {
          setState(() => _hoverAction = false);
          _scheduleHideRevealEye();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _showPlayerTypeDialog,
        onTap: () {
          if (isMobile) {
            _showRevealEye();
            _scheduleHideRevealEye();
          }
          _handleTap();
        },
        child: result,
      ),
    );
    if (_isActive) {
      zone = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * widget.scale),
          boxShadow: const [
            BoxShadow(color: Colors.amberAccent, blurRadius: 12, spreadRadius: 1),
          ],
          border: Border.all(color: Colors.amberAccent, width: 2),
        ),
        child: zone,
      );
    }

    final stack = Stack(
      children: [
        zone,
        if (_isActive && widget.timebankMs != null)
          Positioned(
            top: 4,
            left: 8,
            right: 8,
            child: ActiveTimebar(totalMs: widget.timebankMs!, running: true),
          ),
      ],
    );

    return Offstage(
      offstage: _isBusted,
      child: stack,
    );
  }

  bool _isLeftSide(String? position) {
    switch (position) {
      case 'SB':
      case 'BB':
        return true;
      default:
        return false;
    }
  }

  String _playerTypeIcon(PlayerType type) {
    switch (type) {
      case PlayerType.shark:
        return '🦈';
      case PlayerType.fish:
        return '🐠';
      case PlayerType.callingStation:
        return '📞';
      case PlayerType.maniac:
        return '🔥';
      case PlayerType.nit:
        return '🧊';
      case PlayerType.unknown:
      default:
        return '👤';
    }
  }

  String _playerTypeLabel(PlayerType type) {
    switch (type) {
      case PlayerType.shark:
        return 'Shark';
      case PlayerType.fish:
        return 'Fish';
      case PlayerType.callingStation:
        return 'Calling Station';
      case PlayerType.maniac:
        return 'Maniac';
      case PlayerType.nit:
        return 'Nit';
      case PlayerType.unknown:
      default:
        return 'Unknown';
    }
  }

  Future<void> _showPlayerTypeDialog() async {
    PlayerType selected = _playerType;
    final result = await showDialog<PlayerType>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l = AppLocalizations.of(context)!;
          return AlertDialog(
          title: Text(l.playerType),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PlayerType.values.map((t) {
              return RadioListTile<PlayerType>(
                title: Text('${_playerTypeIcon(t)}  ${_playerTypeLabel(t)}'),
                value: t,
                groupValue: selected,
                onChanged: (val) => setState(() => selected = val!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(l.ok),
            ),
          ],
        );
        },
      ),
    );
    if (result != null) {
      setState(() => _playerType = result);
      widget.onPlayerTypeChanged?.call(result);
    }
  }

  Future<void> _showPlayerTypeMenu(Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect rect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final PlayerType? result = await showMenu<PlayerType>(
      context: context,
      position: rect,
      items: [
        for (final t in PlayerType.values)
          PopupMenuItem<PlayerType>(
            value: t,
            child: Text('${_playerTypeIcon(t)}  ${_playerTypeLabel(t)}'),
          ),
      ],
    );

    if (result != null) {
      setState(() => _playerType = result);
      widget.onPlayerTypeChanged?.call(result);
    }
  }

  Future<void> _handleTap() async {
    if (widget.isFolded) return;
    final result = await _showActionSheet();
    if (result == null) return;
    final String action = result['action'] as String;
    final double? amount = result['amount'] as double?;
    setState(() {
      _actionTagText = amount != null
          ? '${_capitalize(action)} $amount'
          : _capitalize(action);
      if (amount != null) {
        _currentBet = amount;
      }
    });
    final sync = context.read<ActionSyncService>();
    sync.addOrUpdate(pz.ActionEntry(
      playerName: widget.playerName,
      street: widget.street,
      action: action,
      amount: amount,
    ));
  }

  Future<void> _onAddAction() async {
    final result = await _showAddActionDialog();
    if (result == null) return;
    final String action = result['action'] as String;
    final double? amount = result['amount'] as double?;
    final text = amount != null
        ? '${_capitalize(action)} $amount'
        : _capitalize(action);
    if (amount != null) {
      setState(() => _currentBet = amount);
    }
    final color = _lastActionColorFor(action);
    setLastAction(text, color, action, amount);
  }

  Future<Map<String, dynamic>?> _showActionSheet() {
    final TextEditingController controller = TextEditingController();
    String? selected;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final l = AppLocalizations.of(ctx)!;
          final bool needAmount = selected == 'bet' || selected == 'raise';
          return Padding(
            padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'fold'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l.fold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'check'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'action': 'call'}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l.call),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setModal(() => selected = 'bet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Bet'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setModal(() => selected = 'raise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.black87 : Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l.raise),
                ),
                if (needAmount) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.black12,
                      hintText: l.amount,
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final int? amt = int.tryParse(controller.text);
                      if (amt != null) {
                        Navigator.pop(ctx, {
                          'action': selected,
                          'amount': amt,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.blueGrey : Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  child: Text(l.confirm),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  Future<Map<String, dynamic>?> _showAddActionDialog() {
    final controller = TextEditingController();
    String action = 'fold';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final l = AppLocalizations.of(ctx)!;
          final needAmount = action == 'call' || action == 'raise';
          return AlertDialog(
            title: Text(l.selectAction),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: action,
                  items: [
                    DropdownMenuItem(value: 'fold', child: Text(l.fold)),
                    DropdownMenuItem(value: 'call', child: Text(l.call)),
                    DropdownMenuItem(value: 'raise', child: Text(l.raise)),
                    DropdownMenuItem(value: 'push', child: Text(l.push)),
                  ],
                  onChanged: (v) => setState(() => action = v ?? action),
                ),
                if (needAmount)
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.amount),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () {
                  setLastAction(null, Colors.transparent, '', null);
                  Navigator.pop(ctx);
                },
                child: Text(l.clear),
              ),
              TextButton(
                onPressed: () {
                  final amt = needAmount ? int.tryParse(controller.text) : null;
                  Navigator.pop(ctx, {'action': action, 'amount': amt});
                },
                child: Text(l.ok),
              ),
            ],
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  String _streetName(String street) {
    switch (street) {
      case 'Preflop':
        return 'Префлоп';
      case 'Flop':
        return 'Флоп';
      case 'Turn':
        return 'Тёрн';
      case 'River':
        return 'Ривер';
      default:
        return street;
    }
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}
