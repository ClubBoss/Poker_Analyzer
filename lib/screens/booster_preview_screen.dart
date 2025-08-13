import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import 'training_pack_preview_screen.dart';
import '../services/booster_preview_launcher.dart';

class BoosterPreviewScreen extends StatefulWidget {
  const BoosterPreviewScreen({super.key});

  @override
  State<BoosterPreviewScreen> createState() => _BoosterPreviewScreenState();
}

class _BoosterPreviewScreenState extends State<BoosterPreviewScreen> {
  final List<(File, TrainingPackTemplateV2)> _packs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = Directory('yaml_out/boosters');
    if (!dir.existsSync()) {
      setState(() => _loading = false);
      return;
    }
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    final list = <(File, TrainingPackTemplateV2)>[];
    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlString(yaml);
        list.add((file, tpl));
      } catch (_) {}
    }
    list.sort((a, b) => a.$1.path.compareTo(b.$1.path));
    if (!mounted) return;
    setState(() {
      _packs
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  void _open(TrainingPackTemplateV2 tpl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Booster Preview')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _packs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final (file, tpl) = _packs[i];
                return ListTile(
                  title: Text(tpl.name),
                  subtitle: Text('Spots: ${tpl.spotCount}'),
                  onTap: () => _open(tpl),
                  trailing: TextButton.icon(
                    onPressed: () =>
                        const BoosterPreviewLauncher().launch(context, tpl),
                    icon: const Text('▶️'),
                    label: const Text('Предпросмотр'),
                  ),
                );
              },
            ),
    );
  }
}
