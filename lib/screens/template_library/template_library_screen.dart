import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poker_analyzer/models/training_pack_template.dart';
import 'package:poker_analyzer/repositories/template_library_repository.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';

import 'widgets/template_filter_bar.dart';
import 'widgets/template_list_item.dart';

/// Simplified template library screen displaying available templates.
class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  late final TemplateLibraryRepository _repository;
  List<TrainingPackTemplate> _templates = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _repository =
        TemplateLibraryRepository(context.read<TemplateStorageService>());
    _load();
  }

  Future<void> _load() async {
    await _repository.loadLibrary();
    setState(() {
      _templates = context.read<TemplateStorageService>().templates;
    });
  }

  void _applyFilter(String value) {
    setState(() {
      _filter = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filter.isEmpty
        ? _templates
        : _templates
            .where((t) => t.name.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Template Library')),
      body: Column(
        children: [
          TemplateFilterBar(onChanged: _applyFilter),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final t = list[index];
                return TemplateListItem(
                  template: t,
                  onTap: () {
                    // Placeholder for template preview.
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
