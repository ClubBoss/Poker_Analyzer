import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/achievement_engine.dart';
import '../services/user_action_logger.dart';
import '../services/xp_tracker_service.dart';
import '../models/level_stage.dart';
import '../widgets/sync_status_widget.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _boundaryKey = GlobalKey();

  Future<void> _share() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return;
    final bytes = data.buffer.asUint8List();
    final png = img.encodePng(
      img.Image.fromBytes(image.width, image.height, bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/achievements_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(png, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }
  @override
  void initState() {
    super.initState();
    UserActionLogger.instance.log('viewed_achievements');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementEngine>().markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AchievementEngine>();
    final xp = context.watch<XPTrackerService>();
    final stage = stageForLevel(xp.level);
    return RepaintBoundary(
      key: _boundaryKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          centerTitle: true,
          actions: [
            IconButton(onPressed: _share, icon: const Icon(Icons.share)),
            SyncStatusIcon.of(context)
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: engine.achievements.length + 1,
          itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stage.label} Level ${xp.level}',
                    style: TextStyle(
                      color: stage.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${xp.xp} / ${xp.nextLevelXp} XP',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xp.progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(stage.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }
          final a = engine.achievements[index - 1];
          final done = a.completed;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.icon, color: a.stage.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(a.description, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(a.stage.label, style: TextStyle(color: a.stage.color)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (a.progress / a.target).clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(a.stage.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(done ? '✅' : '⏳'),
                    const SizedBox(height: 4),
                    Text(a.stage.label, style: TextStyle(color: a.stage.color)),
                    const SizedBox(height: 4),
                    Text('${a.progress}/${a.target}')
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
