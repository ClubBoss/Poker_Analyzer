import 'package:flutter/material.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_search_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pack_card.dart';
import '../widgets/training_pack_search_bar_widget.dart';
import 'training_pack_preview_screen.dart';

class PackLibrarySearchScreen extends StatefulWidget {
  const PackLibrarySearchScreen({super.key});

  @override
  State<PackLibrarySearchScreen> createState() => _PackLibrarySearchScreenState();
}

class _PackLibrarySearchScreenState extends State<PackLibrarySearchScreen> {
  List<TrainingPackTemplateV2> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    TrainingPackSearchService.instance.init();
    final all = TrainingPackSearchService.instance.query();
    setState(() {
      _results = all;
      _loading = false;
    });
  }

  @override
  void dispose() {
    TrainingPackSearchService.instance.dispose();
    super.dispose();
  }

  void _onChanged(List<TrainingPackTemplateV2> list) {
    setState(() => _results = list);
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Search Library')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TrainingPackSearchBarWidget(onFilterChanged: _onChanged),
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
