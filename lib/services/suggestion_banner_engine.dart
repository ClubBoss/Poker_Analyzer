import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/v2/training_pack_play_screen.dart';
import 'smart_resuggestion_engine.dart';
import 'session_log_service.dart';
import 'suggested_weak_tag_pack_service.dart';
import 'dormant_tag_suggestion_service.dart';
import 'suggestion_cooldown_manager.dart';
import 'training_session_service.dart';
import 'suggestion_banner_ab_test_service.dart';
import 'user_action_logger.dart';

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

    final variant = SuggestionBannerABTestService.instance.getVariant();
    final isAggressive = variant == SuggestionBannerVariant.aggressiveText;

    Future<SuggestionBannerData?> weakBanner() async {
      final weak = await _weakTagService.suggestPack();
      if (weak.pack == null) return null;
      final tpl = weak.pack!;
      await SuggestionCooldownManager.markSuggested(tpl.id);
      final data = _dataFor(
        tpl: tpl,
        title: isAggressive
            ? '🔥 Срочно укрепи базу'
            : '💡 Укрепи базу',
        buttonLabel: isAggressive ? 'Заняться' : 'Начать тренировку',
      );
      await UserActionLogger.instance.logEvent({
        'event': 'suggestion_banner.shown',
        'variant': variant.name,
        'type': 'weak',
      });
      return data;
    }

    Future<SuggestionBannerData?> dormantBanner() async {
      final dormant = await _dormantService.suggestPack();
      if (dormant == null) return null;
      final data = _dataFor(
        tpl: dormant,
        title: isAggressive
            ? '⚡ Верни навык прямо сейчас'
            : '🔁 Освежи навык',
        buttonLabel: isAggressive ? 'Go!' : 'Начать тренировку',
      );
      await UserActionLogger.instance.logEvent({
        'event': 'suggestion_banner.shown',
        'variant': variant.name,
        'type': 'dormant',
      });
      return data;
    }

    Future<SuggestionBannerData?> resuggestBanner() async {
      final re = await _resuggestionEngine.suggestNext();
      if (re == null) return null;
      final data = _dataFor(
        tpl: re,
        title: isAggressive
            ? '🚀 Продолжи обучение!'
            : '♻️ Продолжи обучение',
        buttonLabel: isAggressive ? 'Поехали' : 'Начать тренировку',
      );
      await UserActionLogger.instance.logEvent({
        'event': 'suggestion_banner.shown',
        'variant': variant.name,
        'type': 'resuggest',
      });
      return data;
    }

    late final List<Future<SuggestionBannerData?> Function()> order;
    switch (variant) {
      case SuggestionBannerVariant.layoutA:
        order = [resuggestBanner, dormantBanner, weakBanner];
        break;
      case SuggestionBannerVariant.layoutB:
        order = [dormantBanner, weakBanner, resuggestBanner];
        break;
      default:
        order = [weakBanner, dormantBanner, resuggestBanner];
    }

    for (final step in order) {
      final result = await step();
      if (result != null) return result;
    }

    return null;
  }

  SuggestionBannerData _dataFor({
    required TrainingPackTemplateV2 tpl,
    required String title,
    String buttonLabel = 'Начать тренировку',
  }) {
    return SuggestionBannerData(
      title: title,
      subtitle: 'Пак: ${tpl.name}',
      buttonLabel: buttonLabel,
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
