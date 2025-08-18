// lib/screens/drag_and_drop.dart
import 'package:flutter/material.dart';

class DraggableCard extends StatelessWidget {
  final String imagePath;
  final Offset offset;
  final Function(Offset) onDragEnd;

  const DraggableCard({
    super.key,
    required this.imagePath,
    required this.offset,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Draggable<String>(
        data: imagePath,
        feedback: _buildCardImage(),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildCardImage()),
        onDragEnd: (details) {
          onDragEnd(details.offset);
        },
        child: _buildCardImage(),
      ),
    );
  }

  Widget _buildCardImage() {
    return Image.asset(imagePath, width: 48, height: 64);
  }
}

class CardDropZone extends StatelessWidget {
  final Function(String) onCardDropped;

  const CardDropZone({super.key, required this.onCardDropped});

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 52,
          height: 68,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38),
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
      onAcceptWithDetails: (details) {
        onCardDropped(details.data);
      },
    );
  }
}
