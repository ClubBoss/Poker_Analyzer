import 'package:flutter/material.dart';
import '../services/graph_template_library.dart';
import '../theme/app_colors.dart';
import 'yaml_viewer_screen.dart';

/// Displays available graph templates and allows previewing them.
class GraphTemplateLibraryScreen extends StatelessWidget {
  const GraphTemplateLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = GraphTemplateLibrary.instance;
    final templates = library.listTemplates();
    return Scaffold(
      appBar: AppBar(title: const Text('Graph Templates')),
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final id = templates[i];
          return ListTile(
            title: Text(id),
            onTap: () {
              final yaml = library.getTemplate(id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YamlViewerScreen(yamlText: yaml, title: id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
