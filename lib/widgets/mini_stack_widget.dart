import 'package:flutter/material.dart';
import '../helpers/action_formatting_helper.dart';

/// Small label showing a player's remaining stack in big blinds.
class MiniStackWidget extends StatelessWidget {
  /// Stack value in big blinds.
  final int stack;

  /// Scale factor controlling the size of the widget.
  final double scale;

  const MiniStackWidget({Key? key, required this.stack, this.scale = 1.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stack <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Text(
        '${ActionFormattingHelper.formatAmount(stack)} BB',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
