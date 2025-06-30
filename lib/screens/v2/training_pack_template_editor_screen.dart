import 'package:flutter/material.dart';
import '../../models/v2/training_pack_template.dart';

class TrainingPackTemplateEditorScreen extends StatelessWidget {
  final TrainingPackTemplate template;
  const TrainingPackTemplateEditorScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: const SizedBox.shrink(),
    );
  }
}
