import 'dart:io';
import 'package:flutter/material.dart';
import '../models/v2/training_pack_template.dart';
import '../services/thumbnail_cache_service.dart';

class TrainingPackTemplateCard extends StatefulWidget {
  final TrainingPackTemplate template;
  final VoidCallback? onTap;
  const TrainingPackTemplateCard({super.key, required this.template, this.onTap});

  @override
  State<TrainingPackTemplateCard> createState() => _TrainingPackTemplateCardState();
}

class _TrainingPackTemplateCardState extends State<TrainingPackTemplateCard> {
  String? previewPath;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final path = await ThumbnailCacheService.instance.getThumbnail(widget.template);
    if (!mounted) return;
    setState(() => previewPath = path);
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
            content,
          ],
        ),
      ),
    );
  }
}
