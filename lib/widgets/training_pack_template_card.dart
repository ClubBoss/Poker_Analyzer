import 'dart:io';
import 'package:flutter/material.dart';
import '../models/v2/training_pack_template.dart';
import '../services/thumbnail_cache_service.dart';
import '../services/training_pack_stats_service.dart';

class TrainingPackTemplateCard extends StatefulWidget {
  final TrainingPackTemplate template;
  final VoidCallback? onTap;
  const TrainingPackTemplateCard({super.key, required this.template, this.onTap});

  @override
  State<TrainingPackTemplateCard> createState() => _TrainingPackTemplateCardState();
}

class _TrainingPackTemplateCardState extends State<TrainingPackTemplateCard> {
  String? previewPath;
  bool completed = false;
  bool inProgress = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final path = await ThumbnailCacheService.instance.getThumbnail(widget.template);
    final stat = await TrainingPackStatsService.getStats(widget.template.id);
    final done = await _isFullyCompleted(widget.template);
    var progress = false;
    if (stat != null && widget.template.spots.isNotEmpty) {
      final pct = ((stat.lastIndex + 1) * 100 / widget.template.spots.length).clamp(0, 100);
      progress = pct > 0 && pct < 100;
    }
    if (!mounted) return;
    setState(() {
      previewPath = path;
      completed = done;
      inProgress = progress;
    });
  }

  Future<bool> _isFullyCompleted(TrainingPackTemplate t) async {
    final stat = await TrainingPackStatsService.getStats(t.id);
    if (stat == null || t.spots.isEmpty) return false;
    final progress = ((stat.lastIndex + 1) * 100 / t.spots.length).clamp(0, 100);
    final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
    final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
    return progress == 100 && (stat.accuracy >= .9 || ev >= 90 || icm >= 90);
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Text(widget.template.name,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (previewPath != null)
              Positioned.fill(
                child: Image.file(File(previewPath!), fit: BoxFit.cover),
              ),
            if (previewPath != null)
              Positioned.fill(
                child: Container(color: Colors.black45),
              ),
            if (inProgress && !completed)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🔥 В процессе',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (completed)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '📍 Завершён',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            content,
          ],
        ),
      ),
    );
  }
}
