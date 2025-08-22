import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';

/// Builds connector lines between nodes within the same level.
class SkillTreePathConnectorBuilder {
  SkillTreePathConnectorBuilder();

  /// Returns positioned widgets drawing connectors between consecutive nodes.
  ///
  /// [nodes] must be sorted in the visual order they appear. [bounds] provides
  /// each node's rectangle within the stack coordinate space. [unlockedNodeIds]
  /// controls active coloring of the connectors.
  List<Widget> build({
    required List<SkillTreeNodeModel> nodes,
    required Map<String, Rect> bounds,
    required Set<String> unlockedNodeIds,
    Color activeColor = Colors.amber,
    Color lockedColor = Colors.grey,
    double strokeWidth = 2.0,
    bool showArrow = true,
  }) {
    if (nodes.length < 2) return const [];
    final widgets = <Widget>[];

    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final rectA = bounds[a.id];
      final rectB = bounds[b.id];
      if (rectA == null || rectB == null) continue;

      final start = Offset(rectA.right, rectA.top + rectA.height / 2);
      final end = Offset(rectB.left, rectB.top + rectB.height / 2);
      final rect = Rect.fromPoints(start, end).normalize();
      final active = unlockedNodeIds.contains(a.id);
      final color = active ? activeColor : lockedColor;
      final painter = _ConnectorPainter(
        start: start - rect.topLeft,
        end: end - rect.topLeft,
        color: color,
        strokeWidth: strokeWidth,
        arrow: showArrow && i == nodes.length - 2,
      );
      widgets.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: CustomPaint(painter: painter),
        ),
      );
    }
    return widgets;
  }
}

class _ConnectorPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final bool arrow;

  _ConnectorPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
    required this.arrow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);

    if (arrow) {
      const arrowSize = 6.0;
      final angle = (end - start).direction;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx + arrowSize * math.cos(angle - math.pi / 6),
          end.dy + arrowSize * math.sin(angle - math.pi / 6),
        )
        ..lineTo(
          end.dx + arrowSize * math.cos(angle + math.pi / 6),
          end.dy + arrowSize * math.sin(angle + math.pi / 6),
        )
        ..close();
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.arrow != arrow;
  }
}
