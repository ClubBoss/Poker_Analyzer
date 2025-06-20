import 'package:flutter/material.dart';

/// Overlay that briefly fades the table to black and back.
class TableFadeOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onCompleted;

  const TableFadeOverlay({
    Key? key,
    this.duration = const Duration(milliseconds: 400),
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<TableFadeOverlay> createState() => _TableFadeOverlayState();
}

class _TableFadeOverlayState extends State<TableFadeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse().whenComplete(widget.onCompleted);
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
