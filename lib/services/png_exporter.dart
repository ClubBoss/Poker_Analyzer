import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PngExporter {
  static Future<Uint8List?> _capture(BuildContext context, Widget child) async {
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Center(
        child: Offstage(
          offstage: true,
          child: RepaintBoundary(key: key, child: child),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    Uint8List? bytes;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = data?.buffer.asUint8List();
    }
    entry.remove();
    return bytes;
  }

  static Future<Uint8List?> exportSpot(BuildContext context, Widget spot, {required String label}) {
    return _capture(
      context,
      Stack(
        children: [
          spot,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
