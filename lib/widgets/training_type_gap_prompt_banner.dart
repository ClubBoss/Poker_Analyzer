import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_session_service.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../screens/training_session_screen.dart';

/// Banner prompting the user to train the weakest [TrainingType].
///
/// The banner automatically determines the weakest type using
/// [WeakSpotRecommendationService.detectWeakTrainingType] and suggests the first
/// available pack for that type. The banner can be dismissed for a day.
class TrainingTypeGapPromptBanner extends StatefulWidget {
  /// Currently selected tags. When not empty, the banner is hidden.
  final Set<String> selectedTags;

  /// Active training type filter. When not `null`, the banner is hidden.
  final TrainingType? activeFilter;

  const TrainingTypeGapPromptBanner({
    super.key,
    required this.selectedTags,
    required this.activeFilter,
  });

  @override
  State<TrainingTypeGapPromptBanner> createState() =>
      _TrainingTypeGapPromptBannerState();
}

class _TrainingTypeGapPromptBannerState
    extends State<TrainingTypeGapPromptBanner> {
  static const _hideKey = 'hideWeakTypeUntil';

  bool _loading = true;
  TrainingType? _type;
  TrainingPackTemplate? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final hideStr = prefs.getString(_hideKey);
    final now = DateTime.now();
    if (hideStr != null) {
      final hideUntil = DateTime.tryParse(hideStr);
      if (hideUntil != null && now.isBefore(hideUntil)) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }

    final service = context.read<WeakSpotRecommendationService>();
    final result = await service.detectWeakTrainingType();
    if (result == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final type = TrainingType.values.firstWhereOrNull((e) => e.name == result);
    if (type == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    await PackLibraryLoaderService.instance.loadLibrary();
    final pack = PackLibraryLoaderService.instance.library.firstWhereOrNull(
      (p) => p.trainingType == type,
    );

    if (mounted) {
      setState(() {
        _type = type;
        _pack = pack;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Future<void> _hide() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(days: 1));
    await prefs.setString(_hideKey, until.toIso8601String());
    if (mounted) setState(() => _pack = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null || _type == null)
      return const SizedBox.shrink();
    if (widget.selectedTags.isNotEmpty || widget.activeFilter != null) {
      return const SizedBox.shrink();
    }
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🎯 Ваша слабая зона: ${_type!.label}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _hide,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '🃏 Пак: ${_pack!.name}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Тренировать'),
            ),
          ),
        ],
      ),
    );
  }
}
