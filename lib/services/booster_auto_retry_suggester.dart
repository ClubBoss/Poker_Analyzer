import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_session_service.dart';
import '../screens/training_session_screen.dart';
import 'package:provider/provider.dart';

/// Suggests retrying a booster when accuracy is too low.
class BoosterAutoRetrySuggester {
  BoosterAutoRetrySuggester._();
  static final BoosterAutoRetrySuggester instance =
      BoosterAutoRetrySuggester._();

  static const String _prefsKey = 'booster_retry_dismissed';

  Future<bool> _isDismissed(String boosterId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list.contains(boosterId);
  }

  Future<void> _markDismissed(String boosterId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    if (!list.contains(boosterId)) {
      list.add(boosterId);
      await prefs.setStringList(_prefsKey, list);
    }
  }

  /// Shows a retry snackbar if [accuracy] below [threshold].
  Future<void> maybeSuggestRetry(
    TrainingPackTemplateV2 booster,
    double accuracy,
  ) async {
    const threshold = 60.0;
    if (accuracy >= threshold) return;
    if (await _isDismissed(booster.id)) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.of(ctx);
    final snackBar = SnackBar(
      content: const Text('Сессия прошла с низкой точностью.'),
      action: SnackBarAction(
        label: 'Попробовать ещё раз',
        onPressed: () async {
          await ctx.read<TrainingSessionService>().startSession(booster);
          if (ctx.mounted) {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const TrainingSessionScreen(),
              ),
            );
          }
        },
      ),
    );
    messenger
        .showSnackBar(snackBar)
        .closed
        .then((_) => _markDismissed(booster.id));
  }
}
