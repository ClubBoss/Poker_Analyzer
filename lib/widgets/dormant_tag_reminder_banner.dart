import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:collection/collection.dart';

import '../services/training_gap_detector_service.dart';
import '../services/pack_library_loader_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/user_action_logger.dart';
import '../screens/v2/training_pack_play_screen.dart';

class DormantTagReminderBanner extends StatefulWidget {
  const DormantTagReminderBanner({super.key});

  @override
  State<DormantTagReminderBanner> createState() => _DormantTagReminderBannerState();
}

class _DormantTagReminderBannerState extends State<DormantTagReminderBanner> {
  static const _hideKey = 'hideDormantTagBannerUntil';

  bool _loading = true;
  String? _tag;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    final hideStr = prefs.getString(_hideKey);
    final now = DateTime.now();
    if (hideStr != null) {
      final hideUntil = DateTime.tryParse(hideStr);
      if (hideUntil != null && now.isBefore(hideUntil)) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }

    final list = await TrainingGapDetectorService.detectDormantTags(limit: 1);
    if (list.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final tag = list.first.tag;

    await PackLibraryLoaderService.instance.loadLibrary();
    final pack = PackLibraryLoaderService.instance.library.firstWhereOrNull(
      (p) => p.tags.contains(tag) || (p.meta['focusTag'] == tag),
    );
    if (pack == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await UserActionLogger.instance.log('dormant_tag_suggestion.shown');
    if (mounted) {
      setState(() {
        _tag = tag;
        _pack = pack;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
      ),
    );
  }

  Future<void> _hide() async {
    final prefs = await PreferencesService.getInstance();
    final until = DateTime.now().add(const Duration(days: 1));
    await prefs.setString(_hideKey, until.toIso8601String());
    if (mounted) setState(() => _pack = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null || _tag == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🔁 Освежи навык: $_tag',
                    style: const TextStyle(color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _hide,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Пак: ${_pack!.name}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}

