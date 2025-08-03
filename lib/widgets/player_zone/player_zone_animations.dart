import 'package:flutter/material.dart';

/// Encapsulates animation controllers and sequences for [PlayerZoneWidget].
class PlayerZoneAnimations {
  PlayerZoneAnimations({required TickerProvider vsync}) {
    winnerGlowController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    );
    winnerGlowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(winnerGlowController);
    winnerGlowScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(winnerGlowController);

    winnerHighlightController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );
    winnerHighlightGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(winnerHighlightController);

    allInWinGlowController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    );
    allInWinGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(allInWinGlowController);
  }

  late final AnimationController winnerGlowController;
  late final Animation<double> winnerGlowOpacity;
  late final Animation<double> winnerGlowScale;
  late final AnimationController winnerHighlightController;
  late final Animation<double> winnerHighlightGlow;
  late final AnimationController allInWinGlowController;
  late final Animation<double> allInWinGlow;

  void playWinnerGlow() => winnerGlowController.forward(from: 0.0);
  void resetWinnerGlow() => winnerGlowController.reset();
  void playWinnerHighlight() =>
      winnerHighlightController.forward(from: 0.0);
  void resetWinnerHighlight() => winnerHighlightController.reset();
  void playAllInWinGlow() =>
      allInWinGlowController.forward(from: 0.0);

  void dispose() {
    winnerGlowController.dispose();
    winnerHighlightController.dispose();
    allInWinGlowController.dispose();
  }
}
