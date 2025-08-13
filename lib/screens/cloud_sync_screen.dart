import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/cloud_sync_service.dart';
import '../widgets/sync_status_widget.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  Future<void> _uploadAll() async {
    unawaited(context.read<CloudSyncService>().syncUp());
  }

  Future<void> _download() async {
    await context.read<CloudSyncService>().syncDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: context.read<CloudSyncService>().progress,
              builder: (_, value, __) =>
                  Text('Progress: ${(value * 100).toInt()}%'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploadAll,
              child: const Text('Upload All Local Data'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _download,
              child: const Text('Download from Cloud'),
            ),
          ],
        ),
      ),
    );
  }
}
