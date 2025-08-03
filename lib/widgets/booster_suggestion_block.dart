import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/mistake_tag.dart';
import '../models/mistake_tag_cluster.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/booster_suggestion_engine.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/booster_suggestion_cache.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class BoosterSuggestionBlock extends StatefulWidget {
  final BoosterSuggestionCache cache;
  const BoosterSuggestionBlock({super.key, BoosterSuggestionCache? cache})
      : cache = cache ?? const BoosterSuggestionCache();

  @override
  State<BoosterSuggestionBlock> createState() =>
      _BoosterSuggestionBlockState(cache);
}

class _BoosterSuggestionBlockState extends State<BoosterSuggestionBlock> {
  final BoosterSuggestionCache cache;
  _BoosterSuggestionBlockState(this.cache);

  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final cached = await cache.load();
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _pack = cached;
        _loading = false;
      });
      return;
    }

    final id = await const BoosterSuggestionEngine().suggestBooster();
    if (id != null) {
      await TrainingPackLibraryV2.instance.loadFromFolder();
      final tpl = TrainingPackLibraryV2.instance.getById(id);
      if (tpl != null) {
        await cache.save(tpl);
        if (!mounted) return;
        setState(() {
          _pack = tpl;
          _loading = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _start(TrainingPackTemplateV2 tpl) async {
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  double _clusterMastery(
    String label,
    Map<String, double> masteryMap,
  ) {
    final cluster = MistakeTagCluster.values
        .firstWhereOrNull((c) => c.label == label);
    if (cluster == null) return 0;
    final tags = _clusterTags[cluster] ?? const <MistakeTag>[];
    var sum = 0.0;
    var count = 0;
    for (final t in tags) {
      final m = masteryMap[t.name.toLowerCase()];
      if (m != null) {
        sum += m;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final pack = _pack;
    if (pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<Map<String, double>>(
      future: context.read<TagMasteryService>().computeMastery(),
      builder: (context, snapshot) {
        final masteryMap = snapshot.data ?? {};
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚀 Smart Boosters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: _buildPackTile(pack, masteryMap, accent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackTile(TrainingPackTemplateV2 pack, Map<String, double> masteryMap,
      Color accent) {
    final tag = pack.meta['tag'] as String?;
    final mastery = tag != null
        ? (_clusterMastery(tag, masteryMap) * 100).round()
        : null;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pack.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (tag != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$tag${mastery != null ? ' • $mastery%' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${pack.spotCount} spots',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _start(pack),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Start Training'),
            ),
          )
        ],
      ),
    );
  }
}

const Map<MistakeTagCluster, List<MistakeTag>> _clusterTags = {
  MistakeTagCluster.tightPreflopBtn: [
    MistakeTag.overfoldBtn,
    MistakeTag.overfoldShortStack,
  ],
  MistakeTagCluster.looseCallBlind: [
    MistakeTag.looseCallBb,
    MistakeTag.looseCallSb,
    MistakeTag.looseCallCo,
  ],
  MistakeTagCluster.missedEvOpportunities: [
    MistakeTag.missedEvPush,
    MistakeTag.missedEvCall,
    MistakeTag.missedEvRaise,
  ],
  MistakeTagCluster.aggressiveMistakes: [
    MistakeTag.overpush,
  ],
};
