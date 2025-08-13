import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_preview_spot.dart';
import '../services/training_pack_preview_service.dart';
import 'training_pack_preview_card.dart';

class TrainingPackPreviewPanel extends StatefulWidget {
  final TrainingPackTemplateV2 tpl;
  const TrainingPackPreviewPanel({super.key, required this.tpl});

  @override
  State<TrainingPackPreviewPanel> createState() =>
      _TrainingPackPreviewPanelState();
}

class _TrainingPackPreviewPanelState extends State<TrainingPackPreviewPanel> {
  late Future<List<TrainingPackPreviewSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        Future(() => TrainingPackPreviewService().getPreviewSpots(widget.tpl));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tpl.meta['dynamicParams'] == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<TrainingPackPreviewSpot>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final spots = snapshot.data!;
        if (spots.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
                  Text('Превью', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: spots.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    TrainingPackPreviewCard(spot: spots[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}
