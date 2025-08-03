import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../models/training_type.dart';
import '../services/pack_favorite_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/training_session_launcher.dart';
import '../services/training_progress_logger.dart';

class PackCard extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  final VoidCallback onTap;
  const PackCard({super.key, required this.template, required this.onTap});

  @override
  State<PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<PackCard> {
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.template.id);
  }

  Future<void> _toggleFavorite() async {
    await PackFavoriteService.instance.toggleFavorite(widget.template.id);
    if (mounted) {
      setState(() => _favorite = !_favorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.template.id == TrainingPackLibraryV2.mvpPackId) {
          await TrainingProgressLogger.startSession(widget.template.id);
          await const TrainingSessionLauncher().launch(widget.template);
        } else {
          widget.onTap();
        }
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.template.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(widget.template.trainingType.name,
                      style: const TextStyle(color: Colors.white70)),
                ),
                if (widget.template.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.template.tags.join(', '),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(_favorite ? Icons.star : Icons.star_border),
              color: _favorite ? Colors.amber : Colors.white54,
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}
