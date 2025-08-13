import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/pot_sync_service.dart';
import '../../services/board_reveal_service.dart';
import '../board_display.dart';

class BoardEditor extends StatefulWidget {
  final double scale;
  final int currentStreet;
  final List<CardModel> boardCards;
  final List<CardModel> revealedBoardCards;
  final PotSyncService potSync;
  final void Function(int, CardModel) onCardSelected;
  final void Function(int) onCardLongPress;
  final bool Function(int index)? canEditBoard;
  final Set<String> usedCards;
  final bool editingDisabled;
  final BoardRevealService boardReveal;
  final bool showPot;

  const BoardEditor({
    super.key,
    required this.scale,
    required this.currentStreet,
    required this.boardCards,
    required this.revealedBoardCards,
    required this.onCardSelected,
    required this.onCardLongPress,
    required this.potSync,
    required this.boardReveal,
    this.canEditBoard,
    this.usedCards = const {},
    this.editingDisabled = false,
    this.showPot = true,
  });

  @override
  State<BoardEditor> createState() => BoardEditorState();
}

class BoardEditorState extends State<BoardEditor>
    with TickerProviderStateMixin {
  late int _prevStreet;
  late final BoardRevealService _reveal;

  @override
  void initState() {
    super.initState();
    _prevStreet = widget.currentStreet;
    _reveal = widget.boardReveal;
    _reveal.attachTicker(this);
    _reveal.updateAnimations();
  }

  @override
  void didUpdateWidget(covariant BoardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStreet != widget.currentStreet) {
      _prevStreet = oldWidget.currentStreet;
    }
    _reveal.updateAnimations();
  }

  void cancelPendingReveals() {
    _reveal.cancelBoardReveal();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reversing = widget.currentStreet < _prevStreet;
    return AnimatedSwitcher(
      duration: BoardRevealService.revealDuration,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: reversing ? const Offset(0, -0.1) : const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: BoardDisplay(
        key: ValueKey(widget.currentStreet),
        scale: widget.scale,
        currentStreet: widget.currentStreet,
        boardCards: widget.boardCards,
        revealedBoardCards: widget.revealedBoardCards,
        revealAnimations: _reveal.animations,
        onCardSelected: widget.onCardSelected,
        onCardLongPress: widget.onCardLongPress,
        canEditBoard: widget.canEditBoard,
        usedCards: widget.usedCards,
        editingDisabled: widget.editingDisabled,
        potSync: widget.potSync,
        showPot: widget.showPot,
      ),
    );
  }
}
