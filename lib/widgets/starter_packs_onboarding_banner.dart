import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error_logger.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/pack_library_service.dart';
import '../services/starter_pack_telemetry.dart';
import '../services/training_pack_stats_service.dart';
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
  static bool _shownLogged = false;
  static const _kPrefSeen = 'starter_pack_seen';
  static const _kPrefDismissedLegacy = 'starter_pack_dismissed:v1';
  static const _kPrefDismissedAt = 'starter_pack_dismissed_at';
  static const _kPrefSelectedId = 'starter_pack_selected_id';
  static String _kPrefProgress(String id) => 'starter_pack_progress:$id';
  TrainingPackTemplateV2? _pack;
  bool _loading = true;
  bool _launching = false;
  bool _choosing = false;
  int? _handsCompleted;
  bool _hasChooser = false;
  final Map<String, TrainingPackTemplateV2> _packCache = {};
  final Map<String, Future<int>> _handsFetches = {};

  int _totalHands(TrainingPackTemplateV2 p) =>
      p.spotCount != 0 ? p.spotCount : p.spots.length;

  String _progressText(int done, int total, AppLocalizations t) {
    if (total <= 0) return '0 ${t.hands}';
    final clamped = done.clamp(0, total);
    final percent = (clamped * 100) ~/ total;
    return clamped > 0
        ? '$clamped / $total ${t.hands} • ${t.percentLabel(percent)}'
        : '$total ${t.hands}';
  }

  double _progressValue(int done, int total) {
    if (total <= 0) return 0.0;
    final clamped = done.clamp(0, total);
    return clamped / total;
  }

  void _prefetchPack(TrainingPackTemplateV2 t) {
    unawaited(
      (PackLibraryService.instance.getById(t.id) ?? Future.value(t))
          .then((full) => _packCache[t.id] = full)
          .catchError((_) {}),
    );
  }

  void _setHandsFromCache(SharedPreferences prefs, String id) {
    final c = prefs.getInt(_kPrefProgress(id));
    if (c != null && c >= 0 && mounted) {
      setState(() => _handsCompleted = c);
    }
  }

  void _refreshHandsAndCacheOnce(
    SharedPreferences prefs,
    String id, {
    void Function(int value)? onValue,
  }) {
    final existing = _handsFetches[id];
    final fut = existing ?? TrainingPackStatsService.getHandsCompleted(id);
    if (existing == null) _handsFetches[id] = fut;

    unawaited(
      fut.then((v) async {
        if (v >= 0) {
          await prefs.setInt(_kPrefProgress(id), v);
        }
        if (onValue != null) {
          onValue(v);
        } else if (mounted && _pack?.id == id) {
          setState(() => _handsCompleted = v);
        }
      }).catchError((_) {}).whenComplete(() {
        if (_handsFetches[id] == fut) _handsFetches.remove(id);
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      final legacyDismissed = prefs.getBool(_kPrefDismissedLegacy) ?? false;
      int? dismissedAt = prefs.getInt(_kPrefDismissedAt);
      if (legacyDismissed && dismissedAt == null) {
        await prefs.setInt(_kPrefDismissedAt, now);
        await prefs.remove(_kPrefDismissedLegacy);
        dismissedAt = now;
      }

      final seen = prefs.getBool(_kPrefSeen) ?? false;
      if (dismissedAt != null) {
        if (now - dismissedAt < const Duration(days: 14).inMilliseconds) {
          if (!mounted) return;
          setState(() => _loading = false);
          return;
        } else {
          await prefs.remove(_kPrefDismissedAt);
        }
      }
      final firstRun = !seen;
      if (seen) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final session = context.read<TrainingSessionService>();
      final hasSession = session.currentSession != null;
      final libraryEmpty = PackLibraryService.instance.count() == 0;
      if (hasSession || !(firstRun || libraryEmpty)) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final packFuture = PackLibraryService.instance.recommendedStarter();
      final listFuture = PackLibraryService.instance.listStarters();
      final pack = await packFuture;
      List<TrainingPackTemplateV2> list = const [];
      try {
        list = await listFuture;
      } catch (_) {
        /* swallow */
      }
      TrainingPackTemplateV2? chosen = pack;
      final selectedId = prefs.getString(_kPrefSelectedId);
      if (selectedId != null) {
        var found = false;
        for (final p in list) {
          if (p.id == selectedId) {
            chosen = p;
            found = true;
            break;
          }
        }
        if (!found) {
          await prefs.remove(_kPrefSelectedId);
          chosen = pack;
        }
      }
      final uniqueIds = <String>{
        if (pack != null) pack.id,
        for (final p in list) p.id,
      };
      if (!mounted) return;
      setState(() {
        _pack = chosen;
        _hasChooser = uniqueIds.length >= 2;
        _loading = false;
      });
      if (chosen != null) {
        _prefetchPack(chosen);
        _setHandsFromCache(prefs, chosen.id);
        _refreshHandsAndCacheOnce(prefs, chosen.id);
      }

      if (!_shownLogged && chosen != null) {
        _shownLogged = true;
        final count = _totalHands(chosen);
        unawaited(
          const StarterPackTelemetry().logBanner(
            'starter_banner_shown',
            chosen.id,
            count,
          ),
        );
      }
    } catch (e, st) {
      ErrorLogger.instance.logError('starter_pack_banner_load_failed', e, st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _launchPack(TrainingPackTemplateV2 p, {String? tapEvent}) async {
    if (_launching || !mounted) return;
    setState(() => _launching = true);
    try {
      final cached = _packCache[p.id];
      final full =
          cached ??
          await (PackLibraryService.instance.getById(p.id) ?? Future.value(p));
      _packCache[full.id] = full;
      final count = _totalHands(full);
      if (tapEvent != null) {
        unawaited(
          const StarterPackTelemetry().logBanner(tapEvent, full.id, count),
        );
      }
      if (!mounted) return;
      await const TrainingSessionLauncher().launch(
        full,
        source: 'starter_banner',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefSeen, true);
      unawaited(
        const StarterPackTelemetry().logBanner(
          'starter_banner_launch_success',
          full.id,
          count,
        ),
      );
      if (!mounted) return;
      setState(() => _pack = null);
    } catch (e, st) {
      final count = _totalHands(p);
      unawaited(
        const StarterPackTelemetry().logBanner(
          'starter_banner_launch_failed',
          p.id,
          count,
        ),
      );
      ErrorLogger.instance.logError('starter_pack_banner_start_failed', e, st);
      if (!mounted) return;
      setState(() => _pack = null);
    } finally {
      if (!mounted) return;
      setState(() => _launching = false);
    }
  }

  Future<void> _start() async {
    final p = _pack;
    if (p == null) return;
    final done = _handsCompleted ?? 0;
    final event = done > 0
        ? 'starter_banner_continue_tapped'
        : 'starter_banner_start_tapped';
    await _launchPack(p, tapEvent: event);
  }

  Future<void> _choose() async {
    if (_launching || _choosing) return;
    if (mounted) setState(() => _choosing = true);
    try {
      unawaited(const StarterPackTelemetry().logPickerOpened());

      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString(_kPrefSelectedId);

      final recommended = await PackLibraryService.instance
          .recommendedStarter();

      List<TrainingPackTemplateV2> list = const [];
      try {
        list = await PackLibraryService.instance.listStarters();
      } catch (_) {
        /* swallow */
      }
      if (!mounted || list.isEmpty && recommended == null) return;

      if (recommended != null) {
        list = [
          for (final p in list)
            if (p.id != recommended.id) p,
        ];
      }

      final seen = <String>{};
      final unique = <TrainingPackTemplateV2>[];
      for (final p in list) {
        if (seen.add(p.id)) unique.add(p);
      }

      final t = AppLocalizations.of(context)!;

      // Не блокируем UI: показываем сразу и донаполняем прогрессом
      final all = [...unique, if (recommended != null) recommended];
      final prefill = <String, int>{};
      for (final p in all) {
        final c = prefs.getInt(_kPrefProgress(p.id));
        if (c != null && c >= 0) prefill[p.id] = c;
      }
      final progress = ValueNotifier<Map<String, int>>(prefill);
      for (final p in all) {
        _refreshHandsAndCacheOnce(prefs, p.id, onValue: (v) {
          final map = Map<String, int>.from(progress.value);
          map[p.id] = v;
          progress.value = map;
        });
      }

      final selected = await showModalBottomSheet<TrainingPackTemplateV2>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: ValueListenableBuilder<Map<String, int>>(
              valueListenable: progress,
              builder: (_, prog, __) {
                final items = [...unique];
                items.sort((a, b) {
                  final aSelected = a.id == _pack?.id;
                  final bSelected = b.id == _pack?.id;
                  if (aSelected != bSelected) return aSelected ? -1 : 1;
                  final aDone = prog[a.id] ?? 0;
                  final bDone = prog[b.id] ?? 0;
                  if (aDone != bDone) return bDone.compareTo(aDone);
                  final aTotal = _totalHands(a);
                  final bTotal = _totalHands(b);
                  if (aTotal != bTotal) return bTotal.compareTo(aTotal);
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });

                var dividerIndex = -1;
                for (var i = 0; i < items.length; i++) {
                  final done = prog[items[i].id] ?? 0;
                  if (done == 0) {
                    dividerIndex = i;
                    break;
                  }
                }

                final maxH = MediaQuery.of(context).size.height * 0.7;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (recommended != null)
                          ListTile(
                            leading: const Icon(Icons.star),
                            title: Text(recommended.name),
                            subtitle: Text(() {
                              final total = _totalHands(recommended);
                              final done = prog[recommended.id] ?? 0;
                              return _progressText(done, total, t);
                            }()),
                            selected:
                                selectedId == null && _pack?.id == recommended.id,
                            trailing:
                                selectedId == null && _pack?.id == recommended.id
                                    ? const Icon(Icons.check)
                                    : null,
                            onTap: () => Navigator.of(context).pop(recommended),
                          ),
                        if (recommended != null && items.isNotEmpty)
                          const Divider(height: 0),
                        for (var i = 0; i < items.length; i++) ...[
                          if (i == dividerIndex && dividerIndex > 0)
                            const Divider(height: 0),
                          ListTile(
                            title: Text(items[i].name),
                            subtitle: Text(() {
                              final total = _totalHands(items[i]);
                              final done = prog[items[i].id] ?? 0;
                              return _progressText(done, total, t);
                            }()),
                            selected: items[i].id == _pack?.id,
                            trailing: items[i].id == _pack?.id
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(items[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );

      if (selected == null || !mounted) return;

      if (recommended != null && selected.id == recommended.id) {
        setState(() {
          _pack = recommended;
          _handsCompleted = null;
        });
        _setHandsFromCache(prefs, recommended.id);
        _prefetchPack(recommended);
        _refreshHandsAndCacheOnce(prefs, recommended.id);

        await prefs.remove(_kPrefSelectedId);

        final count = _totalHands(recommended);
        unawaited(
          const StarterPackTelemetry().logPickerSelected(recommended.id, count),
        );

        // По ТЗ — запускаем сразу, без отдельного start_tapped (уже есть picker_selected)
        await _launchPack(recommended);
        return;
      }

      setState(() {
        _pack = selected;
        _handsCompleted = null;
      });
      _setHandsFromCache(prefs, selected.id);
      _prefetchPack(selected);
      _refreshHandsAndCacheOnce(prefs, selected.id);

      await prefs.setString(_kPrefSelectedId, selected.id);

      final count = _totalHands(selected);
      unawaited(
        const StarterPackTelemetry().logPickerSelected(selected.id, count),
      );

      // По ТЗ — запускаем сразу, без отдельного start_tapped (уже есть picker_selected)
      await _launchPack(selected);
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  Future<void> _dismiss() async {
    final p = _pack;
    if (p != null) {
      final count = _totalHands(p);
      unawaited(
        const StarterPackTelemetry().logBanner(
          'starter_banner_dismissed',
          p.id,
          count,
        ),
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kPrefDismissedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // ignore
    } finally {
      if (!mounted) return;
      setState(() => _pack = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.secondary;
    final hands = _totalHands(_pack!);
    final done = _handsCompleted ?? 0;
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
          if (hands > 0) ...[
            Text(
              _progressText(done, hands, t),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: _progressText(done, hands, t),
              child: LinearProgressIndicator(
                value: _progressValue(done, hands),
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasChooser)
                  TextButton(
                    onPressed: (_launching || _choosing) ? null : _choose,
                    child: Text(t.starter_packs_choose),
                  ),
                if (_hasChooser) const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _launching ? null : _start,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: Text(
                    done > 0 ? t.starter_packs_continue : t.starter_packs_start,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
