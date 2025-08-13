import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/suggested_next_pack_engine.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import '../screens/training_pack_preview_screen.dart';

class NextPackRecommendationBanner extends StatefulWidget {
  final String currentPackId;
  const NextPackRecommendationBanner({super.key, required this.currentPackId});

  @override
  State<NextPackRecommendationBanner> createState() =>
      _NextPackRecommendationBannerState();
}

class _NextPackRecommendationBannerState
    extends State<NextPackRecommendationBanner> {
  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final engine = context.read<SuggestedNextPackEngine>();
    final tpl =
        await engine.suggestNextPack(currentPackId: widget.currentPackId);
    if (mounted) {
      setState(() {
        _pack = tpl;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    final template = TrainingPackTemplate.fromJson(tpl.toJson());
    await context.read<TrainingSessionService>().startSession(template);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  void _preview() {
    final tpl = _pack;
    if (tpl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => TrainingPackPreviewScreen(template: tpl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final pack = _pack!;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔜 Next recommended pack:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(pack.name, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: _preview, child: const Text('Preview')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Start'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
