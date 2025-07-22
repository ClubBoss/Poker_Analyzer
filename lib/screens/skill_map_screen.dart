import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';
import '../services/xp_tracker_service.dart';
import '../widgets/skill_card.dart';
import '../widgets/booster_packs_block.dart';
import '../utils/responsive.dart';
import 'library_screen.dart';
import 'tag_insight_screen.dart';

class SkillMapScreen extends StatefulWidget {
  const SkillMapScreen({super.key});

  @override
  State<SkillMapScreen> createState() => _SkillMapScreenState();
}

class _SkillMapScreenState extends State<SkillMapScreen> {
  bool _loading = true;
  Map<String, double> _data = {};
  Map<String, int> _xp = {};
  bool _weakFirst = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final masteryService = context.read<TagMasteryService>();
    final xpService = context.read<XPTrackerService>();
    final map = await masteryService.computeMastery(force: true);
    final xpMap = await xpService.getTotalXpPerTag();
    final entries = map.entries.toList();
    _sort(entries);
    setState(() {
      _data = {for (final e in entries) e.key: e.value};
      _xp = xpMap;
      _loading = false;
    });
  }

  void _sort(List<MapEntry<String, double>> list) {
    list.sort((a, b) =>
        _weakFirst ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
  }

  void _toggleSort() {
    setState(() {
      _weakFirst = !_weakFirst;
      final entries = _data.entries.toList();
      _sort(entries);
      _data = {for (final e in entries) e.key: e.value};
    });
  }

  void _openTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TagInsightScreen(tag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isLandscape(context)
        ? (isCompactWidth(context) ? 6 : 8)
        : (isCompactWidth(context) ? 3 : 4);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Карта навыков'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _toggleSort,
            icon: Icon(_weakFirst ? Icons.arrow_downward : Icons.arrow_upward),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    for (final e in _data.entries)
                      SkillCard(
                        tag: e.key,
                        mastery: e.value,
                        totalXp: _xp[e.key] ?? 0,
                        onTap: () => _openTag(e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const BoosterPacksBlock(),
              ],
            ),
    );
  }
}
