import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cloud_sync_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_spot_storage_service.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final TrainingSpotStorageService _spotStorage =
      const TrainingSpotStorageService();
  int _cloudSpotCount = 0;
  int _cloudHandCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final service = context.read<CloudSyncService>();
    final spots = await service.downloadSpots();
    final hands = await service.downloadHands();
    if (!mounted) return;
    setState(() {
      _cloudSpotCount = spots.length;
      _cloudHandCount = hands.length;
    });
  }

  Future<void> _uploadAll() async {
    final cloud = context.read<CloudSyncService>();
    final handManager = context.read<SavedHandManagerService>();
    final List<TrainingSpot> localSpots = await _spotStorage.load();
    final List<SavedHand> localHands = handManager.hands;
    for (final spot in localSpots) {
      await cloud.uploadSpot(spot);
    }
    for (final hand in localHands) {
      await cloud.uploadHand(hand);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Данные загружены')));
    }
    await _loadCounts();
  }

  Future<void> _download() async {
    final cloud = context.read<CloudSyncService>();
    final spots = await cloud.downloadSpots();
    final hands = await cloud.downloadHands();
    await _spotStorage.save(spots);
    final handManager = context.read<SavedHandManagerService>();
    for (final hand in hands) {
      await handManager.add(hand);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Данные загружены из облака')));
    }
    await _loadCounts();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spots in Cloud: $_cloudSpotCount'),
            const SizedBox(height: 8),
            Text('Hands in Cloud: $_cloudHandCount'),
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

