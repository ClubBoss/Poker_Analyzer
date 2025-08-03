import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

/// A thin wrapper around [DropTarget] used by [TrainingSpotList] to display
/// a drag-and-drop overlay. Keeping it separate allows the list core to stay
/// focused on state management.
class TrainingSpotOverlay extends StatelessWidget {
  final Widget child;
  final void Function(DropDoneDetails)? onDrop;

  const TrainingSpotOverlay({super.key, required this.child, this.onDrop});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: onDrop,
      child: child,
    );
  }
}
