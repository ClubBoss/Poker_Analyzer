import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PngExporter {
  static Future<Uint8List?> _capture(Widget child) async {
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      configuration: ViewConfiguration(
        size: ui.window.physicalSize / ui.window.devicePixelRatio,
        devicePixelRatio: ui.window.devicePixelRatio,
      ),
      window: ui.window,
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    );
    final pipelineOwner = PipelineOwner();
    renderView.attach(pipelineOwner);
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final rootWidget = MaterialApp(home: RepaintBoundary(child: child));
    final adapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: rootWidget,
    );
    adapter.attachToRenderTree(buildOwner);
    buildOwner.buildScope(null);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  static Future<Uint8List?> exportSpot(Widget spot, {required String label}) {
    return _capture(
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
