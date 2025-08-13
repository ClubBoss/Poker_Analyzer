import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/smart_suggestion_engine.dart';
import '../services/training_history_service_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../screens/training_session_screen.dart';
import '../screens/pack_suggestion_preview_screen.dart';

class PackSuggestionBanner extends StatefulWidget {
  const PackSuggestionBanner({super.key});

  @override
  State<PackSuggestionBanner> createState() => _PackSuggestionBannerState();
}

class _PackSuggestionBannerState extends State<PackSuggestionBanner> {
  static bool _shown = false;
  bool _loading = true;
  List<TrainingPackTemplateV2> _packs = [];

  @override
  void initState() {
    super.initState();
    if (_shown) {
      _loading = false;
    } else {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final hist = await TrainingHistoryServiceV2.getHistory(limit: 1);
    if (hist.isNotEmpty &&
        DateTime.now().difference(hist.first.timestamp) <
            const Duration(hours: 48)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final list = await context.read<SmartSuggestionEngine>().suggestNextPacks();
    if (mounted) {
      setState(() {
        _packs = list;
        _loading = false;
      });
    }
  }

  Future<void> _start(BuildContext context, TrainingPackTemplateV2 tpl) async {
    final pack = TrainingPackV2.fromTemplate(tpl, tpl.id);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingSessionScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _packs.isEmpty) return const SizedBox.shrink();
    final p = _packs.first;
    final accent = Theme.of(context).colorScheme.secondary;
    final ev = (p.meta['evScore'] as num?)?.toDouble();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          if (ev != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('EV: ${ev.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70)),
            ),
          if (p.audience != null && p.audience!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(p.audience!,
                  style: const TextStyle(color: Colors.white70)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _start(context, p),
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Начать тренировку'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PackSuggestionPreviewScreen(packs: _packs),
                  ),
                ),
                child: const Text('Другие варианты'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
