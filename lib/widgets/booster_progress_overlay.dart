import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booster_backlink.dart';
import '../models/weak_cluster_info.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/booster_mistake_backlink_engine.dart';

/// Persistent banner shown at the top of a booster session.
///
/// Displays current tags in focus, the originating weak cluster and
/// optional generation date. Can be collapsed by tapping or swiping.
class BoosterProgressOverlay extends StatefulWidget {
  final TrainingPackTemplate booster;
  final List<WeakClusterInfo> clusters;

  const BoosterProgressOverlay({
    super.key,
    required this.booster,
    this.clusters = const [],
  });

  @override
  State<BoosterProgressOverlay> createState() => _BoosterProgressOverlayState();
}

class _BoosterProgressOverlayState extends State<BoosterProgressOverlay> {
  late final BoosterBacklink _link;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    final tmp = TrainingPackTemplateV2.fromTemplate(
      widget.booster,
      type: TrainingType.pushFold,
    );
    final type = const TrainingTypeEngine().detectTrainingType(tmp);
    final tplV2 = TrainingPackTemplateV2.fromTemplate(
      widget.booster,
      type: type,
    );
    _link = const BoosterMistakeBacklinkEngine().link(tplV2, widget.clusters);
  }

  void _toggle() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8);
    final textColor = isDark ? Colors.white : Colors.black;

    final tags = widget.booster.tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final tagText = tags.isNotEmpty
        ? 'Current tags in focus: [${tags.join(', ')}]'
        : null;

    final cluster = _link.sourceCluster;
    final originText = cluster != null
        ? 'Origin: Weak cluster'
        : null;

    final created = widget.booster.createdAt;
    String? genText;
    if (created != null) {
      final date = DateFormat('MMM d', Intl.getCurrentLocale()).format(created);
      genText = 'Generated on $date';
    }

    final content = <Widget>[
      if (tagText != null) Text(tagText),
      if (originText != null) Text(originText),
      if (genText != null) Text(genText, style: TextStyle(fontSize: 12)),
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: GestureDetector(
          onTap: _toggle,
          onVerticalDragEnd: (_) => _toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _collapsed
                ? Center(
                    child: Icon(Icons.expand_more, color: textColor),
                  )
                : DefaultTextStyle(
                    style: TextStyle(color: textColor),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
