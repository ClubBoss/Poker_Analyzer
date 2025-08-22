import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/graph_path_authoring_wizard_screen.dart';
import 'graph_path_template_generator.dart';

/// Central registry of reusable graph templates.
class GraphTemplateLibrary {
  GraphTemplateLibrary._();

  /// Singleton instance.
  static final GraphTemplateLibrary instance = GraphTemplateLibrary._();

  final Map<String, String> _templates = {
    'cash_vs_mtt': const GraphPathTemplateGenerator()
        .generateCashVsMttTemplate(),
    'live_vs_online': const GraphPathTemplateGenerator()
        .generateLiveVsOnlineTemplate(),
    'icm_intro': const GraphPathTemplateGenerator().generateIcmIntroTemplate(),
    'heads_up_intro': const GraphPathTemplateGenerator()
        .generateHeadsUpIntroTemplate(),
  };

  /// IDs of available templates.
  List<String> listTemplates() => List.unmodifiable(_templates.keys);

  /// Returns YAML template with [id] or empty string if not found.
  String getTemplate(String id) => _templates[id] ?? '';

  /// Imports a YAML graph from file and opens it in the authoring wizard.
  Future<void> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['yaml', 'yml'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final yaml = await File(path).readAsString();
      const id = 'imported_graph';
      _templates[id] = yaml;
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        await Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) =>
                GraphPathAuthoringWizardScreen(initialTemplateId: id),
          ),
        );
      }
    } catch (_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to import YAML file')),
        );
      }
    }
  }
}
