import 'package:flutter/material.dart';

class CardDropZone extends StatelessWidget {
  final String label;
  final void Function()? onCardDropped;

  const CardDropZone({super.key, required this.label, this.onCardDropped});

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (_) {
        if (onCardDropped != null) {
          onCardDropped!();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 60,
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.amber : Colors.white24,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
