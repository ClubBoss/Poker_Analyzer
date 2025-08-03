import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a temporary tooltip above a path node explaining
/// why it is locked.
class PathNodeUnlockHintOverlay {
  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String message,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || renderBox == null) return;

    final target = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Stack(
          children: [
            Positioned(
              left: target.dx + size.width / 2,
              top: target.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.0),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(entry);
    Timer(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }
}
