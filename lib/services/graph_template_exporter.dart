import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'graph_template_library.dart';

/// Exports graph templates to YAML files.
class GraphTemplateExporter {
  const GraphTemplateExporter();

  /// Saves the template with [templateId] as a YAML file chosen by the user.
  Future<void> exportTemplate(String templateId) async {
    final yaml = GraphTemplateLibrary.instance.getTemplate(templateId);
    if (yaml.isEmpty) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Template not found')),
        );
      }
      return;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Graph Template',
      fileName: '$templateId.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
    );
    if (savePath == null) return;

    try {
      await File(savePath).writeAsString(yaml, flush: true);
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final name = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('Exported: $name')));
      }
    } catch (_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Failed to export template')),
        );
      }
    }
  }
}
