import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'player_stack_chips.dart';
import 'player_zone/player_stack_value.dart';

/// Widget that fades out a player's cards and stack after losing.
class LossFadeWidget extends StatefulWidget {
  final List<Offset> cardPositions;
  final Offset stackChipPos;
  final Offset stackValuePos;
  final List<CardModel> cards;
  final int stack;
  final double scale;
  final VoidCallback? onCompleted;

  const LossFadeWidget({
    Key? key,
    required this.cardPositions,
    required this.stackChipPos,
    required this.stackValuePos,
    required this.cards,
    required this.stack,
    this.scale = 1.0,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<LossFadeWidget> createState() => _LossFadeWidgetState();
}

class _LossFadeWidgetState extends State<LossFadeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _opacity = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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

  Widget _buildCard(CardModel card) {
    final isRed = card.suit == '♥' || card.suit == '♦';
    return Container(
      width: 36 * widget.scale,
      height: 52 * widget.scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3 * widget.scale,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${card.rank}${card.suit}',
        style: TextStyle(
          color: isRed ? Colors.red : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18 * widget.scale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _opacity,
        child: Stack(
          children: [
            Positioned(
              left: widget.stackChipPos.dx,
              top: widget.stackChipPos.dy,
              child: PlayerStackChips(
                stack: widget.stack,
                scale: widget.scale * 0.9,
              ),
            ),
            Positioned(
              left: widget.stackValuePos.dx,
              top: widget.stackValuePos.dy,
              child: PlayerStackValue(
                stack: widget.stack,
                scale: widget.scale * 0.9,
              ),
            ),
            for (
              int i = 0;
              i < widget.cardPositions.length && i < widget.cards.length;
              i++
            )
              Positioned(
                left: widget.cardPositions[i].dx - 18 * widget.scale,
                top: widget.cardPositions[i].dy - 26 * widget.scale,
                child: _buildCard(widget.cards[i]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inserts a [LossFadeWidget] above the current overlay.
void showLossFadeOverlay({
  required BuildContext context,
  required List<Offset> cardPositions,
  required Offset stackChipPos,
  required Offset stackValuePos,
  required List<CardModel> cards,
  required int stack,
  double scale = 1.0,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => LossFadeWidget(
      cardPositions: cardPositions,
      stackChipPos: stackChipPos,
      stackValuePos: stackValuePos,
      cards: cards,
      stack: stack,
      scale: scale,
      onCompleted: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
