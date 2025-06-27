import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import 'create_pack_from_template_screen.dart';

class TemplateLibraryScreen extends StatelessWidget {
  const TemplateLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateStorageService>().templates;
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны')),
      body: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (context, i) {
          final t = templates[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
              title: Text(t.name),
              subtitle: Text('${t.category ?? 'Без категории'} • ${t.hands.length}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreatePackFromTemplateScreen(template: t)),
              ),
            ),
          );
        },
      ),
    );
  }
}
