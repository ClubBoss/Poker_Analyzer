import 'package:flutter/material.dart';
import 'package:poker_analyzer/models/training_pack_template.dart';

/// Simple list item used in the template library.
class TemplateListItem extends StatelessWidget {
  const TemplateListItem(
      {super.key, required this.template, this.note, this.onTap});

  final TrainingPackTemplate template;
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(template.name),
        subtitle: note != null ? Text(note!) : null,
        onTap: onTap,
      ),
    );
  }
}
