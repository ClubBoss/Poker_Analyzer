import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../services/recent_packs_service.dart';
import '../services/user_action_logger.dart';
import '../services/template_storage_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

class QuickAccessMenu extends StatelessWidget {
  const QuickAccessMenu({super.key});

  Future<void> _open(
    BuildContext context,
    RecentPack pack, {
    required bool primary,
  }) async {
    final storage = context.read<TemplateStorageService>();
    final template = storage.templates.firstWhereOrNull((t) => t.id == pack.id);
    if (template == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pack not found')));
      await RecentPacksService.instance.remove(pack.id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: template),
      ),
    );
    UserActionLogger.instance.logEvent({
      'event':
          primary ? 'quick_access.resume_click' : 'quick_access.recent_click',
      'packId': pack.id,
    });
    await RecentPacksService.instance.record(template);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return ValueListenableBuilder<List<RecentPack>>(
      valueListenable: RecentPacksService.instance.listenable,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No recent packs',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        final last = value.first;
        final others = value.skip(1).take(4).toList();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _open(context, last, primary: true),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: Text('Resume ${last.name}'),
                ),
              ),
              for (final p in others)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => _open(context, p, primary: false),
                ),
            ],
          ),
        );
      },
    );
  }
}
