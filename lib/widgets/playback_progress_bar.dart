import 'package:flutter/material.dart';

/// Interactive progress bar for seeking within hand playback.
class PlaybackProgressBar extends StatelessWidget {
  final int playbackIndex;
  final int actionCount;
  final ValueChanged<int> onSeek;

  const PlaybackProgressBar({
    super.key,
    required this.playbackIndex,
    required this.actionCount,
    required this.onSeek,
  });

  void _handleSeek(BuildContext context, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final fraction = (local.dx / box.size.width).clamp(0.0, 1.0);
    onSeek((fraction * actionCount).round());
  }

  @override
  Widget build(BuildContext context) {
    final progress = actionCount > 0 ? playbackIndex / actionCount : 0.0;
    final accent = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) => _handleSeek(context, details.globalPosition),
      onHorizontalDragUpdate: (details) =>
          _handleSeek(context, details.globalPosition),
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ),
    );
  }
}
