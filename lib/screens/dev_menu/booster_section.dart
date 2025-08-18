import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/booster_refiner_engine.dart';
import '../../services/booster_similarity_pruner.dart';
import '../../services/booster_tag_coverage_stats.dart';

class BoosterSection extends StatefulWidget {
  const BoosterSection({super.key});

  @override
  State<BoosterSection> createState() => _BoosterSectionState();
}

class _BoosterSectionState extends State<BoosterSection> {
  bool _tagCoverageLoading = false;
  bool _refineLoading = false;
  bool _pruneLoading = false;

  Future<void> _showTagCoverageStats() async {
    if (_tagCoverageLoading || !kDebugMode) return;
    setState(() => _tagCoverageLoading = true);
    final text = await const BoosterTagCoverageStats().buildReport();
    if (!mounted) return;
    setState(() => _tagCoverageLoading = false);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Booster Tag Stats'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refineBoosters() async {
    if (_refineLoading || !kDebugMode) return;
    setState(() => _refineLoading = true);
    final count = await const BoosterRefinerEngine().refineAll();
    if (!mounted) return;
    setState(() => _refineLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Обновлено: $count')));
  }

  Future<void> _pruneDuplicates() async {
    if (_pruneLoading || !kDebugMode) return;
    setState(() => _pruneLoading = true);
    final count = await const BoosterSimilarityPruner().pruneAndSaveAll();
    if (!mounted) return;
    setState(() => _pruneLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Обновлено: $count')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (kDebugMode)
          ListTile(
            title: const Text('📊 Статистика тэгов booster\'ов'),
            onTap: _tagCoverageLoading ? null : _showTagCoverageStats,
          ),
        if (kDebugMode)
          ListTile(
            title: const Text('🛠 Улучшить booster паки'),
            onTap: _refineLoading ? null : _refineBoosters,
          ),
        if (kDebugMode)
          ListTile(
            title: const Text('🧹 Удалить дубликаты в booster паках'),
            onTap: _pruneLoading ? null : _pruneDuplicates,
          ),
      ],
    );
  }
}
