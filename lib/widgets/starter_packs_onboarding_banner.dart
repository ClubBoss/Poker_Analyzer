import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error_logger.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/training_session_service.dart';
import '../theme/app_colors.dart';

class StarterPacksOnboardingBanner extends StatefulWidget {
  const StarterPacksOnboardingBanner({super.key});

  @override
  State<StarterPacksOnboardingBanner> createState() =>
      _StarterPacksOnboardingBannerState();
}

class _StarterPacksOnboardingBannerState
    extends State<StarterPacksOnboardingBanner> {
  TrainingPackTemplateV2? _pack;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = context.read<TrainingSessionService>();
      if (session.currentSession != null) {
        setState(() => _loading = false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final firstRun = !(prefs.getBool('starter_pack_seen') ?? false);
      if (PackLibraryService.instance.count() != 0 && !firstRun) {
        setState(() => _loading = false);
        return;
      }
      final pack = await PackLibraryService.instance.recommendedStarter();
      if (!mounted) return;
      setState(() {
        _pack = pack;
        _loading = false;
      });
    } catch (e, st) {
      ErrorLogger.instance
          .logError('starter_pack_banner_load_failed', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    final p = _pack;
    if (p == null) return;
    try {
      final full = await PackLibraryService.instance.getById(p.id) ?? p;
      await const TrainingSessionLauncher().launch(full);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('starter_pack_seen', true);
    } catch (e, st) {
      ErrorLogger.instance
          .logError('starter_pack_banner_start_failed', e, st);
      if (mounted) setState(() => _pack = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.starter_packs_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(t.starter_packs_subtitle,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(t.starter_packs_start),
            ),
          ),
        ],
      ),
    );
  }
}

