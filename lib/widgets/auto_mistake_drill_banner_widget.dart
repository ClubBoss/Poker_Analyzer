import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mistake_history_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/mistake_drill_launcher_service.dart';
import '../services/mistake_driven_drill_pack_generator.dart';
import '../services/mistake_history_query_service.dart';
import '../services/template_storage_service.dart';
import '../services/mistake_review_pack_service.dart';

class AutoMistakeDrillBannerWidget extends StatefulWidget {
  const AutoMistakeDrillBannerWidget({super.key});

  @override
  State<AutoMistakeDrillBannerWidget> createState() => _AutoMistakeDrillBannerWidgetState();
}

class _AutoMistakeDrillBannerWidgetState extends State<AutoMistakeDrillBannerWidget> {
  bool _show = false;
  late final MistakeDrillLauncherService _service;

  @override
  void initState() {
    super.initState();
    _service = MistakeDrillLauncherService(
      generator: MistakeDrivenDrillPackGenerator(
        history: _MistakePackHistory(context.read<MistakeReviewPackService>()),
        loadSpot: _loadSpot,
      ),
    );
    _prepare();
  }

  Future<void> _prepare() async {
    if (!await _service.shouldTriggerAutoDrill()) return;
    final pack = await _service.generator.generate(limit: 5);
    if (pack == null || pack.spots.isEmpty) return;
    await _service.markShown();
    if (mounted) setState(() => _show = true);
  }

  Future<TrainingPackSpot?> _loadSpot(String id) async {
    final templates = context.read<TemplateStorageService>().templates;
    for (final t in templates) {
      for (final s in t.spots) {
        if (s.id == id) {
          return TrainingPackSpot.fromJson(s.toJson());
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: const Text('Fix Your Mistakes'),
        subtitle: const Text('You have mistakes to correct'),
        trailing: TextButton(
          onPressed: () {
            _service.maybeLaunch();
          },
          child: const Text('Train Now'),
        ),
      ),
    );
  }
}

class _MistakePackHistory extends MistakeHistoryQueryService {
  final MistakeReviewPackService _source;
  _MistakePackHistory(this._source)
      : super(
          loadSpottings: () async => [],
          resolveTags: (_) async => [],
          resolveStreet: (_) async => null,
        );

  @override
  Future<List<MistakeHistoryEntry>> queryMistakes({
    String? tag,
    String? street,
    String? spotIdPattern,
    int limit = 20,
  }) async {
    final entries = <MistakeHistoryEntry>[];
    for (final pack in _source.packs) {
      for (final id in pack.spotIds) {
        entries.add(MistakeHistoryEntry(
          spotId: id,
          timestamp: pack.createdAt,
          decayStage: '',
          tag: '',
          wasRecovered: false,
        ));
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }
}
