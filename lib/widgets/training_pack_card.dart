import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pinned_pack_service.dart';
import '../theme/app_colors.dart';
import '../helpers/mistake_category_translations.dart';

class TrainingPackCard extends StatefulWidget {
  final TrainingPackTemplate template;
  final VoidCallback onTap;
  const TrainingPackCard(
      {super.key, required this.template, required this.onTap});

  @override
  State<TrainingPackCard> createState() => _TrainingPackCardState();
}

class _TrainingPackCardState extends State<TrainingPackCard> {
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    _pinned = widget.template.isPinned;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.template.spots
        .map((s) => s.mistakeCategory)
        .whereType<String>()
        .toSet()
        .toList();
    return GestureDetector(
      onLongPress: () async {
        await context.read<PinnedPackService>().toggle(widget.template.id);
        if (mounted)
          setState(() {
            _pinned = !_pinned;
            widget.template.isPinned = _pinned;
          });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_pinned)
                        const Text('📌 ',
                            style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: Text(
                          widget.template.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (widget.template.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.template.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${widget.template.spots.length} spots',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final c in categories)
                            InputChip(
                              label: Text(
                                translateMistakeCategory(c),
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () {},
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: widget.onTap, child: const Text('Train')),
          ],
        ),
      ),
    );
  }
}
