import 'package:flutter/material.dart';

import '../core/training/controller/built_in_library_controller.dart';
import '../models/v2/training_pack_v2.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  List<TrainingPackV2> _packs = [];

  @override
  void initState() {
    super.initState();
    BuiltInLibraryController.instance.preload().then((_) {
      if (!mounted) return;
      setState(() {
        _packs = BuiltInLibraryController.instance.getPacks();
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView.separated(
        itemCount: _packs.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Встроенные тренировки',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }
          final pack = _packs[index - 1];
          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrainingSessionScreen(pack: pack),
                ),
              );
            },
            title: Text(pack.name),
            subtitle: pack.tags.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in pack.tags.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ),
                        if (pack.tags.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${pack.tags.length - 3}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${pack.spotCount}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }
}
