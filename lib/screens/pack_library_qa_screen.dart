import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/pack_library_loader_service.dart';
import '../services/pack_library_qa_engine.dart';
import '../models/pack_warning.dart';
import '../theme/app_colors.dart';

class PackLibraryQAScreen extends StatefulWidget {
  const PackLibraryQAScreen({super.key});
  @override
  State<PackLibraryQAScreen> createState() => _PackLibraryQAScreenState();
}

class _PackLibraryQAScreenState extends State<PackLibraryQAScreen> {
  bool _loading = true;
  final List<PackWarning> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_qaTask, '');
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll([for (final j in data) PackWarning.fromJson(j)]);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('QA библиотеки')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('🔄 Обновить'),
                ),
                const SizedBox(height: 16),
                for (final w in _items)
                  ListTile(
                    title: Text(w.packId),
                    subtitle: Text('${w.type}: ${w.message}'),
                  ),
              ],
            ),
    );
  }
}

Future<List<Map<String, dynamic>>> _qaTask(String _) async {
  await PackLibraryLoaderService.instance.loadLibrary();
  final list = PackLibraryLoaderService.instance.library;
  final res = const PackLibraryQAEngine().run(list);
  return [for (final w in res) w.toJson()];
}
