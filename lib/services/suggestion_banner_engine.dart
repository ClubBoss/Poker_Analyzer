import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/v2/training_pack_play_screen.dart';
import 'smart_resuggestion_engine.dart';
import 'session_log_service.dart';
import 'suggested_weak_tag_pack_service.dart';
import 'dormant_tag_suggestion_service.dart';
import 'pack_suggestion_cooldown_service.dart';
import 'training_session_service.dart';

class SuggestionBannerData {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  SuggestionBannerData({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });
}

class SuggestionBannerEngine {
  final SessionLogService logs;
  final SuggestedWeakTagPackService _weakTagService;
  final DormantTagSuggestionService _dormantService;
  final SmartReSuggestionEngine _resuggestionEngine;

  SuggestionBannerEngine({
    required this.logs,
    SuggestedWeakTagPackService? weakTagService,
    DormantTagSuggestionService? dormantService,
    SmartReSuggestionEngine? resuggestionEngine,
  })  : _weakTagService = weakTagService ?? const SuggestedWeakTagPackService(),
        _dormantService = dormantService ?? const DormantTagSuggestionService(),
        _resuggestionEngine =
            resuggestionEngine ?? SmartReSuggestionEngine(logs: logs);

  Future<bool> shouldShowBanner() async => true;

  Future<SuggestionBannerData?> getBanner() async {
    if (!await shouldShowBanner()) return null;

    final weak = await _weakTagService.suggestPack();
    if (weak.pack != null) {
      final tpl = weak.pack!;
      await PackSuggestionCooldownService.markAsSuggested(tpl.id);
      return _dataFor(
        tpl: tpl,
        title: '💡 \u0423\u043a\u0440\u0435\u043f\u0438 \u0431\u0430\u0437\u0443',
      );
    }

    final dormant = await _dormantService.suggestPack();
    if (dormant != null) {
      return _dataFor(
        tpl: dormant,
        title: '🔁 \u041e\u0441\u0432\u0435\u0436\u0438 \u043d\u0430\u0432\u044b\u043a',
      );
    }

    final re = await _resuggestionEngine.suggestNext();
    if (re != null) {
      return _dataFor(
        tpl: re,
        title: '♻️ \u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438 \u043e\u0431\u0443\u0447\u0435\u043d\u0438\u0435',
      );
    }

    return null;
  }

  SuggestionBannerData _dataFor({
    required TrainingPackTemplateV2 tpl,
    required String title,
  }) {
    return SuggestionBannerData(
      title: title,
      subtitle: 'Пак: ${tpl.name}',
      buttonLabel: 'Начать тренировку',
      onTap: () async {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return;
        await ctx.read<TrainingSessionService>().startSession(tpl);
        if (!ctx.mounted) return;
        await Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
          ),
        );
      },
    );
  }
}
