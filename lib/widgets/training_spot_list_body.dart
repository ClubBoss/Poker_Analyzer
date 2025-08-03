import 'package:flutter/material.dart';

import '../models/training_spot.dart';

class TrainingSpotListBody extends StatelessWidget {
  final List<TrainingSpot> spots;
  final Set<TrainingSpot> selected;
  final void Function(TrainingSpot) onToggle;
  final Future<void> Function(TrainingSpot) onDelete;
  final VoidCallback onAddTag;
  final VoidCallback onRemoveTag;
  final VoidCallback onExportCsv;

  const TrainingSpotListBody({
    super.key,
    required this.spots,
    required this.selected,
    required this.onToggle,
    required this.onDelete,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final s = spots[index];
            final isSelected = selected.contains(s);
            final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
            final stack = s.stacks.isNotEmpty ? s.stacks[s.heroIndex] : 0;
            return Dismissible(
              key: ValueKey(s.createdAt),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await onDelete(s);
                return false;
              },
              child: ListTile(
                leading: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(s),
                ),
                title: Text('$pos ${stack}bb'),
                subtitle: s.tags.isNotEmpty ? Text(s.tags.join(', ')) : null,
                onTap: () => onToggle(s),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: selected.isNotEmpty ? 56 : 0,
            child: selected.isNotEmpty
                ? Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                            onPressed: onAddTag,
                            child: const Text('🏷 Add Tag')),
                        ElevatedButton(
                            onPressed: onRemoveTag,
                            child: const Text('❌ Remove Tag')),
                        ElevatedButton(
                            onPressed: onExportCsv,
                            child: const Text('📄 Export CSV')),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
