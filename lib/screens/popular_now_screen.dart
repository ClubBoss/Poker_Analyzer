import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack.dart';
import '../helpers/color_utils.dart';
import '../widgets/difficulty_chip.dart';
import '../theme/app_colors.dart';
import 'training_pack_screen.dart';

class PopularNowScreen extends StatefulWidget {
  const PopularNowScreen({super.key});

  @override
  State<PopularNowScreen> createState() => _PopularNowScreenState();
}

class _PopularNowScreenState extends State<PopularNowScreen> {
  late Future<List<(TrainingPack, int)>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TrainingPackStorageService>().getTrendingPacks();
  }

  Future<void> _reload() async {
    _future = context.read<TrainingPackStorageService>().getTrendingPacks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(TrainingPack, int)>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('🔥 Популярное')),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : (data == null || data.isEmpty)
              ? const Center(
                  child: Text('Пусто', style: TextStyle(color: Colors.white70)),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Часто тренируются сейчас',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final pack = item.$1;
                          final count = item.$2;
                          return ListTile(
                            leading: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            title: Text(pack.name),
                            subtitle: Row(
                              children: [
                                if (pack.colorTag.isNotEmpty)
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: colorFromHex(pack.colorTag),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                DifficultyChip(pack.difficulty),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TrainingPackScreen(pack: pack),
                                ),
                              );
                              if (mounted) _reload();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
