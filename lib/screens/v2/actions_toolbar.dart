import 'package:flutter/material.dart';

/// Bottom toolbar with actions for the template editor.
class ActionsToolbar extends StatelessWidget {
  final VoidCallback onAdd;
  const ActionsToolbar({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add spot',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
