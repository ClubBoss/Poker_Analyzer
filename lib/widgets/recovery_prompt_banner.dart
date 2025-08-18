import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/skill_recovery_pack_engine.dart';
import '../services/training_history_service_v2.dart';
import '../services/user_action_logger.dart';
import '../services/training_session_service.dart';
import '../services/suggestion_cooldown_manager.dart';
import '../services/suggested_training_packs_history_service.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/v2/training_pack_play_screen.dart';

class RecoveryPromptBanner extends StatefulWidget {
  const RecoveryPromptBanner({super.key});

  @override
  State<RecoveryPromptBanner> createState() => _RecoveryPromptBannerState();
}

class _RecoveryPromptBannerState extends State<RecoveryPromptBanner> {
  static const _hideKey = 'recovery_prompt_hide_until';
  static const _gap = Duration(days: 10);

  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hideStr = prefs.getString(_hideKey);
    if (hideStr != null) {
      final hideUntil = DateTime.tryParse(hideStr);
      if (hideUntil != null && now.isBefore(hideUntil)) {
        setState(() => _loading = false);
        return;
      }
    }

    final history = await TrainingHistoryServiceV2.getHistory(limit: 1);
    if (history.isEmpty || now.difference(history.first.timestamp) < _gap) {
      setState(() => _loading = false);
      return;
    }

    final pack = await SkillRecoveryPackEngine.suggestRecoveryPack();
    if (pack != null) {
      await UserActionLogger.instance.log('recovery_prompt.shown');
      await SuggestionCooldownManager.markSuggested(pack.id);
      await SuggestedTrainingPacksHistoryService.logSuggestion(
        packId: pack.id,
        source: 'recovery_prompt_banner',
      );
    }
    if (mounted) {
      setState(() {
        _pack = pack;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _hideKey,
      DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
    );
    if (mounted) setState(() => _pack = null);
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await UserActionLogger.instance.log('recovery_prompt.clicked');
    final template = TrainingPackTemplate.fromJson(tpl.toJson());
    await context.read<TrainingSessionService>().startSession(template);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackPlayScreen(template: template, original: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final pack = _pack!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🔁 Вернись в форму',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Пак: ${pack.name}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Продолжить тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
