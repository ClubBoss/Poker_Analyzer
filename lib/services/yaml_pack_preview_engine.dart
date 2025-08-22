import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class YamlPackPreviewEngine {
  YamlPackPreviewEngine();

  double? _coverage(TrainingPackTemplateV2 p) {
    final total =
        (p.meta['totalWeight'] as num?)?.toDouble() ?? p.spotCount.toDouble();
    if (total == 0) return null;
    final ev = (p.meta['evCovered'] as num?)?.toDouble() ?? 0;
    final icm = (p.meta['icmCovered'] as num?)?.toDouble() ?? 0;
    return (ev + icm) * 100 / (2 * total);
  }

  Widget buildPreview(TrainingPackTemplateV2 pack) {
    final ev = (pack.meta['evScore'] as num?)?.toDouble();
    final icm = (pack.meta['icmScore'] as num?)?.toDouble();
    final coverage = _coverage(pack);
    final tags = pack.tags.join(', ');
    final pos = pack.positions.join(', ');
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pack.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (pack.goal.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  pack.goal,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🏷️ $tags',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            if (pos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🪑 $pos',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  if (ev != null)
                    Text(
                      'EV ${ev.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  if (icm != null)
                    Text(
                      'ICM ${icm.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 12,
                      ),
                    ),
                  if (coverage != null)
                    Text(
                      '📈 ${coverage.round()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    '🃏 ${pack.spotCount}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
