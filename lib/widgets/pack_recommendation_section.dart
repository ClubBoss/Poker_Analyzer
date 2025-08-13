import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../services/pack_library_index_loader.dart';
import '../services/pack_similarity_engine.dart';
import '../screens/training_pack_preview_screen.dart';
import 'pack_card.dart';

class PackRecommendationSection extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  const PackRecommendationSection({super.key, required this.template});

  @override
  State<PackRecommendationSection> createState() =>
      _PackRecommendationSectionState();
}

class _PackRecommendationSectionState extends State<PackRecommendationSection> {
  List<TrainingPackTemplateV2> _packs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PackRecommendationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.id != widget.template.id) {
      _load();
    }
  }

  Future<void> _load() async {
    await PackLibraryIndexLoader.instance.load();
    final res = const PackSimilarityEngine().findSimilar(widget.template.id);
    if (mounted) {
      setState(() {
        _packs = res.take(3).toList();
      });
    }
  }

  void _open(TrainingPackTemplateV2 tpl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_packs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '🤝 Похожие паки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _packs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 180,
                child: PackCard(
                  template: _packs[i],
                  onTap: () => _open(_packs[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
