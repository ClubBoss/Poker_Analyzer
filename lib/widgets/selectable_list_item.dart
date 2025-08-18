import 'package:flutter/material.dart';

class SelectableListItem extends StatelessWidget {
  final Widget child;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SelectableListItem({
    super.key,
    required this.child,
    required this.selectionMode,
    required this.selected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.blueGrey.shade700 : null;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: color,
        padding: selectionMode ? const EdgeInsets.only(left: 8) : null,
        child: Row(
          children: [
            if (selectionMode)
              Checkbox(value: selected, onChanged: (_) => onTap?.call()),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
