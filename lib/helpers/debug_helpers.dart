import 'package:flutter/material.dart';

import '../models/action_evaluation_request.dart';
import '../widgets/evaluation_request_tile.dart';

/// Displays a simple diagnostic line with a label and value.
Widget debugDiag(String label, Object? value) {
  final String valueStr = value?.toString() ?? '';
  return Text('$label: $valueStr');
}

/// Shows a check mark or mismatch details based on [ok].
Widget debugCheck(String label, bool ok, String a, String b) {
  final String text = ok
      ? '$label: ✅'
      : '$label: ❌ ${a.toString()} vs ${b.toString()}';
  return Text(text);
}

/// Renders a reorderable list section for debugging evaluation queues.
Widget debugQueueSection(
  String label,
  List<ActionEvaluationRequest> queue,
  ReorderCallback onReorder,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      debugDiag('$label Queue', queue.length),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: queue.length,
        itemBuilder: (context, index) {
          final ActionEvaluationRequest r = queue[index];
          return EvaluationRequestTile(
            key: ValueKey(r.id),
            request: r,
            showDragHandle: true,
            index: index,
          );
        },
        onReorder: onReorder,
      ),
      const SizedBox(height: 12),
    ],
  );
}
