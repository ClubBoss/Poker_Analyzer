import 'package:flutter/material.dart';

/// Groups animation controllers related to player labels and textual overlays.
class PlayerZoneLabelAnimations {
  PlayerZoneLabelAnimations({
    required TickerProvider vsync,
    required bool isHero,
  }) {
    showdownLabelController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    showdownLabelOpacity = CurvedAnimation(
      parent: showdownLabelController,
      curve: Curves.easeIn,
    );

    finalStackController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    finalStackOpacity = CurvedAnimation(
      parent: finalStackController,
      curve: Curves.easeIn,
    );
    finalStackOffset =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: finalStackController, curve: Curves.easeOut),
        );

    winnerLabelController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    );
    winnerLabelOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(winnerLabelController);
    winnerLabelScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.9,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(winnerLabelController);

    heroLabelController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    heroLabelOpacity = CurvedAnimation(
      parent: heroLabelController,
      curve: Curves.easeIn,
    );
    heroLabelScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: heroLabelController, curve: Curves.easeOut),
    );
    if (isHero) {
      heroLabelController.forward();
    }

    victoryController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    );
    victoryOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      const TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(victoryController);
  }

  late final AnimationController showdownLabelController;
  late final Animation<double> showdownLabelOpacity;
  late final AnimationController finalStackController;
  late final Animation<double> finalStackOpacity;
  late final Animation<Offset> finalStackOffset;
  late final AnimationController winnerLabelController;
  late final Animation<double> winnerLabelOpacity;
  late final Animation<double> winnerLabelScale;
  late final AnimationController heroLabelController;
  late final Animation<double> heroLabelOpacity;
  late final Animation<double> heroLabelScale;
  late final AnimationController victoryController;
  late final Animation<double> victoryOpacity;

  void dispose() {
    showdownLabelController.dispose();
    finalStackController.dispose();
    winnerLabelController.dispose();
    heroLabelController.dispose();
    victoryController.dispose();
  }
}
