import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../services/suggested_weak_tag_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/user_action_logger.dart';
import '../services/suggestion_cooldown_manager.dart';
import '../screens/training_session_screen.dart';

class SuggestedWeakTagPackBanner extends StatefulWidget {
  const SuggestedWeakTagPackBanner({super.key});

  @override
  State<SuggestedWeakTagPackBanner> createState() =>
      _SuggestedWeakTagPackBannerState();
}

class _SuggestedWeakTagPackBannerState
    extends State<SuggestedWeakTagPackBanner> {
  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final result = await const SuggestedWeakTagPackService().suggestPack();
    if (result.isFallback && result.pack != null) {
      await UserActionLogger.instance.log(
        'suggested_pack_banner.fallback_shown',
      );
    }
    if (result.pack != null) {
      await SuggestionCooldownManager.markSuggested(result.pack!.id);
    }
    if (mounted) {
      setState(() {
        _pack = result.pack;
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

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
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
          const Text(
            '💡 \u0423\u043a\u0440\u0435\u043f\u0438 \u0431\u0430\u0437\u0443',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u043c\u044b\u0439 \u043f\u0430\u043a: ${_pack!.name}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text(
                '\u041d\u0430\u0447\u0430\u0442\u044c \u0442\u0440\u0435\u043d\u0438\u0440\u043e\u0432\u043a\u0443',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
