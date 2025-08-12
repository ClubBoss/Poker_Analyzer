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
  bool _launching = false;

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
      final seen = prefs.getBool('starter_pack_seen') ?? false;
      final dismissed = prefs.getBool('starter_pack_dismissed:v1') ?? false;
      if (seen || dismissed) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final firstRun = !seen;
      if (PackLibraryService.instance.count() != 0 && !firstRun) {
        if (mounted) setState(() => _loading = false);
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
    if (p == null || _launching) return;
    setState(() => _launching = true);
    try {
      final full = await PackLibraryService.instance.getById(p.id) ?? p;
      if (!mounted) return;
      await const TrainingSessionLauncher().launch(full);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('starter_pack_seen', true);
      if (mounted) setState(() => _pack = null);
    } catch (e, st) {
      ErrorLogger.instance
          .logError('starter_pack_banner_start_failed', e, st);
      if (mounted) setState(() => _pack = null);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _dismiss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('starter_pack_dismissed:v1', true);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _pack = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.secondary;
    final hands =
        _pack!.spotCount != 0 ? _pack!.spotCount : _pack!.spots.length;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  t.starter_packs_title,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, size: 18),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.starter_packs_subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          if (_pack!.name.isNotEmpty)
            Text(
              _pack!.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (hands > 0)
            Text(
              '$hands ${t.hands}',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _launching ? null : _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(t.starter_packs_start),
            ),
          ),
        ],
      ),
    );
  }
}

