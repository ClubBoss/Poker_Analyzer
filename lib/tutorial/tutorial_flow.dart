import 'package:flutter/material.dart';

class TutorialStep {
  final GlobalKey targetKey;
  final String description;
  final void Function(BuildContext context, TutorialFlow flow)? onNext;

  TutorialStep({
    required this.targetKey,
    required this.description,
    this.onNext,
  });
}

class TutorialFlow {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  int _index = 0;
  OverlayEntry? _entry;

  TutorialFlow(this.steps, {this.onComplete});

  void start(BuildContext context) {
    _index = 0;
    _show(context);
  }

  void next(BuildContext context) {
    _entry?.remove();
    if (_index >= steps.length) return;
    final action = steps[_index].onNext;
    _index++;
    if (action != null) {
      action(context, this);
    }
    if (_index >= steps.length) {
      onComplete?.call();
    }
  }

  void showCurrentStep(BuildContext context) {
    if (_index < steps.length) _show(context);
  }

  void _show(BuildContext context) {
    final step = steps[_index];
    final overlay = Overlay.of(context);
    final renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          const ModalBarrier(color: Colors.black54, dismissible: false),
          Positioned(
            left: offset.dx - 4,
            top: offset.dy - 4,
            width: size.width + 8,
            height: size.height + 8,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => next(context),
                        child: const Text('Далее'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }
}
