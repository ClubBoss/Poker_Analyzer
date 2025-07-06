import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/v2/training_pack_template.dart';

class PackBundleInfo {
  final String path;
  final TrainingPackTemplate template;
  PackBundleInfo(this.path, this.template);
}

class PackBundleViewerScreen extends StatefulWidget {
  const PackBundleViewerScreen({super.key});

  @override
  State<PackBundleViewerScreen> createState() => _PackBundleViewerScreenState();
}

class _PackBundleViewerScreenState extends State<PackBundleViewerScreen> {
  final List<PackBundleInfo> _bundles = [];

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['pka']);
    if (result == null) return;
    final items = <PackBundleInfo>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final data = await File(path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(data);
        final tplFile = archive.files.firstWhere((e) => e.name == 'template.json');
        final json = jsonDecode(utf8.decode(tplFile.content)) as Map<String, dynamic>;
        final tpl = TrainingPackTemplate.fromJson(json);
        items.add(PackBundleInfo(path, tpl));
      } catch (_) {}
    }
    items.sort((a, b) {
      final ad = a.template.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.template.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bd.compareTo(ad);
      if (cmp != 0) return cmp;
      final aa = (a.template.evCovered + a.template.icmCovered) / 2;
      final bb = (b.template.evCovered + b.template.icmCovered) / 2;
      return bb.compareTo(aa);
    });
    setState(() {
      _bundles
        ..clear()
        ..addAll(items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bundle Viewer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(onPressed: _pick, child: const Text('Select Bundles')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _bundles.length,
              itemBuilder: (_, i) {
                final b = _bundles[i];
                final tpl = b.template;
                final coverage = (tpl.evCovered + tpl.icmCovered) / 2;
                final date = tpl.lastGeneratedAt;
                return ListTile(
                  title: Text(tpl.name),
                  subtitle: Text([
                    if (date != null) date.toLocal().toString().split('.').first,
                    '${coverage.round()}%'
                  ].join(' · ')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
