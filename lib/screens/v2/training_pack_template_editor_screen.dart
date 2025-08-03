import 'package:flutter/material.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';

import 'spot_list_section.dart';
import 'statistics_pane.dart';
import 'actions_toolbar.dart';

/// High level screen for editing a [TrainingPackTemplate].
///
/// The implementation is intentionally lightweight – the heavy
/// UI pieces live in dedicated widgets imported above.  This keeps
/// the file focused on composition and makes each part easier to
/// maintain.
class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final List<TrainingPackTemplate> templates;
  final bool readOnly;

  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    this.templates = const [],
    this.readOnly = false,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() =>
      _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState
    extends State<TrainingPackTemplateEditorScreen> {
  TrainingPackSpot? _selected;

  void _onSpotSelected(TrainingPackSpot spot) {
    setState(() => _selected = spot);
  }

  void _addSpot() {
    // Placeholder for future spot creation logic.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      body: Row(
        children: [
          Expanded(
            child: SpotListSection(
              spots: widget.template.spots,
              onSelected: _onSpotSelected,
              selectedId: _selected?.id,
            ),
          ),
          Expanded(
            child: StatisticsPane(template: widget.template),
          ),
        ],
      ),
      bottomNavigationBar: ActionsToolbar(onAdd: _addSpot),
    );
  }
}
