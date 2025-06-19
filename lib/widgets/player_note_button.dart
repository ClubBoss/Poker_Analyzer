import 'package:flutter/material.dart';

/// Icon button for editing a player's note with optional tooltip display.
class PlayerNoteButton extends StatelessWidget {
  final String? note;
  final double scale;
  final VoidCallback onPressed;

  const PlayerNoteButton({
    Key? key,
    required this.note,
    required this.onPressed,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.isNotEmpty;

    Widget button = IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 16 * scale,
      onPressed: onPressed,
      icon: Icon(
        Icons.sticky_note_2,
        color: hasNote ? Colors.amber : Colors.white70,
        size: 16 * scale,
      ),
    );

    if (!hasNote) return button;

    return Tooltip(
      message: note!,
      triggerMode: TooltipTriggerMode.longPress,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white),
      child: button,
    );
  }
}
