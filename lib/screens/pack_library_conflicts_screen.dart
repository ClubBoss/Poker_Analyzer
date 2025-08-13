import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/pack_library_conflict_scanner.dart';

class PackLibraryConflictsScreen extends StatefulWidget {
  const PackLibraryConflictsScreen({super.key});
  @override
  State<PackLibraryConflictsScreen> createState() =>
      _PackLibraryConflictsScreenState();
}

class _PackLibraryConflictsScreenState
    extends State<PackLibraryConflictsScreen> {
  bool _loading = true;
  final List<(String, String)> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await compute(_scanTask, '');
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll([for (final e in res) (e[0], e[1])]);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Конфликты библиотеки')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                    onPressed: _load, child: const Text('🔄 Обновить')),
                const SizedBox(height: 16),
                for (final i in _items)
                  ListTile(
                    title: Text(
                        File(i.$1).path.split(Platform.pathSeparator).last),
                    subtitle: Text(i.$2),
                  ),
              ],
            ),
    );
  }
}

Future<List<List<String>>> _scanTask(String _) async {
  final res = await const PackLibraryConflictScanner().scanConflicts();
  return [
    for (final e in res) [e.$1, e.$2]
  ];
}
