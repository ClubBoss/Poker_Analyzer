import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/v2/training_pack_template_v2.dart';
import 'training_pack_exporter_v2.dart';

class TrainingPackClipboardSharer {
  const TrainingPackClipboardSharer._();

  static Future<void> copyToClipboard(
    TrainingPackTemplateV2 pack, {
    BuildContext? context,
  }) async {
    final yaml = const TrainingPackExporterV2().exportYaml(pack);
    await Clipboard.setData(ClipboardData(text: yaml));
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('YAML copied to clipboard')));
    }
  }
}
