import 'package:flutter/material.dart';

/// Overlay used to fade the table to black before resetting state.
class TableCleanupOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onCompleted;

  const TableCleanupOverlay({
    Key? key,
    this.duration = const Duration(milliseconds: 400),
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<TableCleanupOverlay> createState() => _TableCleanupOverlayState();
}

class _TableCleanupOverlayState extends State<TableCleanupOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(color: Colors.black87),
    );
  }
}
