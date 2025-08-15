// Example:
// Navigator.of(context).push(MaterialPageRoute(
//   builder: (_) => const DevMenuPage(),
// ));

import 'package:flutter/material.dart';

import 'daily_quick_play.dart';
import 'demo_seed.dart';
import 'mvs_player.dart';
import 'plan_runner.dart';
import 'quickstart_launcher.dart';
import 'mistakes_quick_play.dart';

class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev menu')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Play demo spots'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      Scaffold(body: MvsSessionPlayer(spots: demoSpots())),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Quickstart launcher'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickstartLauncherPage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Quickstart (defaults)'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlayFromPlanPage(
                    planPath: 'out/plan/play_plan_v1.json',
                    bundleDir: 'dist/training_v1',
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Daily quick play'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickDailyPlayPage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Daily quick play (custom)'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickDailyPlayPage(
                    planPath: 'out/plan/play_plan_v1.json',
                    bundleDir: 'dist/training_v1',
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Play manifest (enter path)'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickstartLauncherPage(
                    initialManifest:
                        'out/l4_sessions/session_icm_v1_mvs_k1_n20.json',
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Mistakes quick play'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickMistakesPlayPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

