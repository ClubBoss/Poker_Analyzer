import 'package:flutter/material.dart';

/// Overlay that fades street name in and out when the street changes.
class StreetTransitionOverlay extends StatefulWidget {
  final String streetName;
  final VoidCallback onComplete;
  const StreetTransitionOverlay({
    Key? key,
    required this.streetName,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StreetTransitionOverlay> createState() =>
      _StreetTransitionOverlayState();
}

class _StreetTransitionOverlayState extends State<StreetTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
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
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: Text(
            widget.streetName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
