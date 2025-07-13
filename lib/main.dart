// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_initializer.dart';
import 'app_bootstrap.dart';
import 'helpers/training_pack_storage.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/weakness_overview_screen.dart';
import 'screens/v2/training_pack_play_screen.dart';
import 'services/cloud_sync_service.dart';
import 'services/connectivity_sync_controller.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/user_action_logger.dart';
import 'widgets/first_launch_overlay.dart';
import 'widgets/sync_status_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await AppInitializer.init();
  runApp(app);
}

class PokerAIAnalyzerApp extends StatefulWidget {
  const PokerAIAnalyzerApp({super.key});

  @override
  State<PokerAIAnalyzerApp> createState() => _PokerAIAnalyzerAppState();
}

class _PokerAIAnalyzerAppState extends State<PokerAIAnalyzerApp> {
  late final ConnectivitySyncController _sync;

  Future<void> _maybeShowIntroOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_intro_overlay') == true) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showFirstLaunchOverlay(ctx, () async {
      final p = await SharedPreferences.getInstance();
      await p.setBool('seen_intro_overlay', true);
    });
  }

  Future<void> _maybeResumeTraining() async {
    final prefs = await SharedPreferences.getInstance();
    String? id;
    int ts = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith('tpl_prog_')) {
        final pack = k.substring(9);
        final t = prefs.getInt('tpl_ts_$pack') ?? 0;
        if (t > ts) {
          ts = t;
          id = pack;
        }
      }
    }
    if (id == null || ts == 0) return;
    if (DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts))
            .inHours >
        12) return;
    final templates = await TrainingPackStorage.load();
    final tpl = templates.firstWhereOrNull((t) => t.id == id);
    if (tpl == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text('Resume "${tpl.name}"?'),
        content: const Text('You were in the middle of a training pack.'),
        actions: [
          TextButton(
            onPressed: () {
              if (dCtx.mounted) Navigator.pop(dCtx, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (dCtx.mounted) Navigator.pop(dCtx, true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sync = AppBootstrap.sync!;
    context.read<UserActionLogger>().log('opened_app');
    unawaited(NotificationService.scheduleDailyReminder(context));
    unawaited(NotificationService.scheduleDailyProgress(context));
    NotificationService.startRecommendedPackTask(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeResumeTraining();
      _maybeShowIntroOverlay();
    });
  }

  @override
  void dispose() {
    AppBootstrap.dispose();
    context.read<CloudSyncService>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SyncStatusWidget(
      sync: _sync,
      cloud: context.read<CloudSyncService>(),
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeService>().mode;
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Poker AI Analyzer',
            debugShowCheckedModeBanner: false,
            themeMode: theme,
            theme: context.read<ThemeService>().lightTheme,
            darkTheme: context.read<ThemeService>().darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('ru'),
              Locale('pt'),
              Locale('de'),
            ],
            routes: {
              WeaknessOverviewScreen.route: (_) =>
                  const WeaknessOverviewScreen(),
            },
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return const Locale('ru');
              for (final l in supportedLocales) {
                if (l.languageCode == locale.languageCode) return l;
              }
              return const Locale('ru');
            },
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
