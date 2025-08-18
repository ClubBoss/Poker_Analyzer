import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/training/export/training_pack_exporter_v2.dart';
import '../../models/v2/training_pack_template_v2.dart';
import '../../theme/app_colors.dart';

class TrainingPackYamlPreviewer extends StatelessWidget {
  final TrainingPackTemplateV2 pack;
  const TrainingPackYamlPreviewer({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final yaml = const TrainingPackExporterV2().exportYaml(pack);
    return Scaffold(
      appBar: AppBar(
        title: Text(pack.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yaml));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(
            yaml,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

Future<void> showTrainingPackYamlPreviewer(
  BuildContext context,
  TrainingPackTemplateV2 pack,
) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TrainingPackYamlPreviewer(pack: pack)),
  );
}
