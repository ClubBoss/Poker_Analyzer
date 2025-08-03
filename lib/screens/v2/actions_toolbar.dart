import 'package:flutter/material.dart';

class ActionsToolbar extends StatelessWidget {
  final VoidCallback onAddSpot;
  final VoidCallback onSave;

  const ActionsToolbar({
    super.key,
    required this.onAddSpot,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'addSpot',
          onPressed: onAddSpot,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'saveTemplate',
          onPressed: onSave,
          child: const Icon(Icons.save),
        ),
      ],
    );
  }
}
