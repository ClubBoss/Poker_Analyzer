import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_selector.dart';

class PlayerZoneWidget extends StatefulWidget {
  final String playerName;
  final String? position;
  final List<CardModel> cards;
  final bool isHero;
  final bool isFolded;
  final bool isActive;
  final bool highlightLastAction;
  final bool showHint;
  final String? actionTagText;
  final Function(CardModel) onCardsSelected;
  final double scale;
  final int stack;
  final VoidCallback? onStackTap;

  const PlayerZoneWidget({
    Key? key,
    required this.playerName,
    this.position,
    required this.cards,
    required this.isHero,
    required this.isFolded,
    required this.onCardsSelected,
    this.isActive = false,
    this.highlightLastAction = false,
    this.showHint = false,
    this.actionTagText,
    this.scale = 1.0,
    required this.stack,
    this.onStackTap,
  }) : super(key: key);

  @override
  State<PlayerZoneWidget> createState() => _PlayerZoneWidgetState();
}

class _PlayerZoneWidgetState extends State<PlayerZoneWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PlayerZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller
        ..reset()
        ..repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14 * widget.scale,
    );
    final captionStyle = TextStyle(
      color: _getPositionColor(widget.position),
      fontSize: 12 * widget.scale,
      fontWeight: FontWeight.bold,
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
                if (widget.isHero)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0 * widget.scale),
                    child: Icon(
                      Icons.star,
                      color: Colors.orangeAccent,
                      size: 14 * widget.scale,
                    ),
                  ),
              ],
            ),
            if (widget.position != null)
              Padding(
                padding: EdgeInsets.only(top: 2.0 * widget.scale),
                child: Text(
                  widget.position!,
                  style: captionStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 2.0 * widget.scale),
              child: GestureDetector(
                onTap: widget.onStackTap,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _ChipStack(
                    key: ValueKey(widget.stack),
                    count: widget.stack,
                    scale: widget.scale,
                  ),
                ),
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

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelWithIcon,
        SizedBox(height: 4 * widget.scale),
        GestureDetector(
          onTap: () async {
            final card = await showCardSelector(context);
            if (card != null) {
              widget.onCardsSelected(card);
            }
          },
          child: Opacity(
            opacity: widget.isFolded ? 0.4 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
              final card = index < widget.cards.length ? widget.cards[index] : null;
              final isRed = card?.suit == '♥' || card?.suit == '♦';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36 * widget.scale,
                height: 52 * widget.scale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(card == null ? 0.3 : 1),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: card != null
                    ? Text(
                        '${card.rank}${card.suit}',
                        style: TextStyle(
                          color: isRed ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * widget.scale,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.grey),
              );
            }),
            ),
          ),
        ),
        if (widget.actionTagText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.0 * widget.scale),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * widget.scale, vertical: 2 * widget.scale),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10 * widget.scale),
              ),
              child: Text(
                widget.actionTagText!,
                style: tagStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );

    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        column,
      ],
    );

    Widget result = content;

    if (widget.isFolded) {
      result = ClipRect(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Opacity(opacity: 0.6, child: result),
        ),
      );
    }

    result = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(2 * widget.scale),
      decoration: (widget.isActive || widget.highlightLastAction)
          ? BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 3),
              borderRadius: BorderRadius.circular(12 * widget.scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: 8,
                )
              ],
            )
          : null,
      child: result,
    );

    result = ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: result,
    );

    return result;
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'BTN':
        return Colors.amber;
      case 'SB':
      case 'BB':
        return Colors.blueAccent;
      default:
        return Colors.white70;
    }
  }
}

class _ChipStack extends StatelessWidget {
  final int count;
  final double scale;

  const _ChipStack({Key? key, required this.count, required this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chipCount = count.clamp(0, 10);
    final chips = List<Widget>.generate(chipCount, (index) {
      return Container(
        margin: EdgeInsets.only(top: index == 0 ? 0 : 2 * scale),
        width: 12 * scale,
        height: 12 * scale,
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 10)
          Text(
            '10+',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * scale,
            ),
          ),
        ...chips,
      ],
    );
  }
}
