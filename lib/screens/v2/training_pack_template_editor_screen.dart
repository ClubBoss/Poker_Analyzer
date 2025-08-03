import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/hand_data.dart';

import 'spot_list_section.dart';
import 'statistics_pane.dart';
import 'actions_toolbar.dart';

class TrainingPackTemplateEditorScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  final bool readOnly;

  const TrainingPackTemplateEditorScreen({
    super.key,
    required this.template,
    this.readOnly = false,
  });

  @override
  State<TrainingPackTemplateEditorScreen> createState() =>
      _TrainingPackTemplateEditorScreenState();
}

class _TrainingPackTemplateEditorScreenState
    extends State<TrainingPackTemplateEditorScreen> {
  void _addSpot() {
    setState(() {
      widget.template.spots.add(
        TrainingPackSpot(
          id: const Uuid().v4(),
          title: 'New spot',
          hand: HandData(),
        ),
      );
    });
  }

  void _save() {
    // TODO: implement persistence
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Template saved')));
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
              onAdd: widget.readOnly ? null : _addSpot,
            ),
          ),
          StatisticsPane(spots: widget.template.spots),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : ActionsToolbar(
              onAddSpot: _addSpot,
              onSave: _save,
            ),
    );
  }
}
