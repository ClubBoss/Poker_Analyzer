import 'package:flutter/material.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';

import '../services/smart_resume_engine.dart';
import '../screens/v2/training_pack_play_screen.dart';

class PackResumeBanner extends StatefulWidget {
  const PackResumeBanner({super.key});

  @override
  State<PackResumeBanner> createState() => _PackResumeBannerState();
}

class _PackResumeBannerState extends State<PackResumeBanner> {
  UnfinishedPack? _pack;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SmartResumeEngine.instance.getRecentUnfinished(limit: 1);
    if (!mounted) return;
    setState(() => _pack = list.isNotEmpty ? list.first : null);
  }

  Future<void> _resume() async {
    final p = _pack;
    if (p == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackPlayScreen(template: p.template, original: p.template),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    if (pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final l = AppLocalizations.of(context)!;
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
          Text(
            pack.template.name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.unfinishedSession,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _resume,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(l.resume),
            ),
          ),
        ],
      ),
    );
  }
}
