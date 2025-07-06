import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        PipelineOwner,
        RenderObjectToWidgetAdapter,
        RenderPositionedBox,
        RenderRepaintBoundary,
        RenderView;

class PngExporter {
  static Future<Uint8List?> _capture(Widget child) async {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        size: view.physicalSize / view.devicePixelRatio,
        devicePixelRatio: view.devicePixelRatio,
      ),
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    );
    final pipelineOwner = PipelineOwner();
    renderView.attach(pipelineOwner);
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final adapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MaterialApp(home: child),
    );
    adapter.attachToRenderTree(buildOwner);
    buildOwner.buildScope(null);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    final image = await boundary.toImage(pixelRatio: view.devicePixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  static Future<Uint8List?> exportWidget(Widget child) {
    return _capture(child);
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
