import 'package:flutter/material.dart';
import '../services/pack_search_index_service.dart';
import '../services/training_pack_library_loader_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_preview_screen.dart';
import '../widgets/pack_card.dart';
import '../theme/app_colors.dart';

class PackLibrarySearchScreen extends StatefulWidget {
  const PackLibrarySearchScreen({super.key});

  @override
  State<PackLibrarySearchScreen> createState() => _PackLibrarySearchScreenState();
}

class _PackLibrarySearchScreenState extends State<PackLibrarySearchScreen> {
  final _controller = TextEditingController();
  List<TrainingPackTemplateV2> _results = [];

  @override
  void initState() {
    super.initState();
    final templates =
        TrainingPackLibraryLoaderService.instance.loadedTemplates;
    PackSearchIndexService.instance.buildIndex(templates);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text.trim();
    final res = PackSearchIndexService.instance.search(q);
    setState(() => _results = res);
  }

  Future<void> _open(TrainingPackTemplateV2 tpl) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Library')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Search'),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tpl = _results[index];
                return PackCard(
                  template: tpl,
                  onTap: () => _open(tpl),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
