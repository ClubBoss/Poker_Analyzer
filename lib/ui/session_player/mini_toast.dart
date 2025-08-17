import 'dart:async';
import 'package:flutter/material.dart';

Future<void> showMiniToast(
  BuildContext context,
  String text, {
  Duration duration = const Duration(milliseconds: 1200),
}) async {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  final animation = ValueNotifier<double>(0.0);

  entry = OverlayEntry(
    builder: (ctx) {
      final opacity = animation.value.clamp(0.0, 1.0);
      final dy = 16.0 * (1.0 - opacity); // slight upward slide
      return Positioned(
        top: MediaQuery.of(ctx).padding.top + 12 + dy,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(text, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  // fade in
  for (int i = 0; i <= 6; i++) {
    await Future.delayed(const Duration(milliseconds: 20));
    animation.value = i / 6.0;
  }
  // hold
  await Future.delayed(duration - const Duration(milliseconds: 400));
  // fade out
  for (int i = 0; i <= 6; i++) {
    await Future.delayed(const Duration(milliseconds: 20));
    animation.value = 1.0 - i / 6.0;
  }
  entry.remove();
}
