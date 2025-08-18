import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/training_pack_filter_service.dart';

class PackFilterDebugScreen extends StatefulWidget {
  const PackFilterDebugScreen({super.key});

  @override
  State<PackFilterDebugScreen> createState() => _PackFilterDebugScreenState();
}

class _PackFilterDebugScreenState extends State<PackFilterDebugScreen> {
  final _evCtr = TextEditingController();
  final _icmCtr = TextEditingController();
  final _diffCtr = TextEditingController();
  final _minSpotsCtr = TextEditingController();
  final _maxSpotsCtr = TextEditingController();
  final _rarityCtr = TextEditingController();
  final _matchCtr = TextEditingController();
  final List<String> _packs = [];
  bool _loading = false;

  @override
  void dispose() {
    _evCtr.dispose();
    _icmCtr.dispose();
    _diffCtr.dispose();
    _minSpotsCtr.dispose();
    _maxSpotsCtr.dispose();
    _rarityCtr.dispose();
    _matchCtr.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _loading = true);
    final res = await const TrainingPackFilterService().filter(
      minEv: double.tryParse(_evCtr.text),
      minIcm: double.tryParse(_icmCtr.text),
      maxDifficulty: double.tryParse(_diffCtr.text),
      minSpots: int.tryParse(_minSpotsCtr.text),
      maxSpots: int.tryParse(_maxSpotsCtr.text),
      minRarity: double.tryParse(_rarityCtr.text),
      minTagsMatch: double.tryParse(_matchCtr.text),
    );
    if (!mounted) return;
    setState(() {
      _packs
        ..clear()
        ..addAll(res);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Filter')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _evCtr,
              decoration: const InputDecoration(labelText: 'min EV'),
            ),
            TextField(
              controller: _icmCtr,
              decoration: const InputDecoration(labelText: 'min ICM'),
            ),
            TextField(
              controller: _diffCtr,
              decoration: const InputDecoration(labelText: 'max difficulty'),
            ),
            TextField(
              controller: _minSpotsCtr,
              decoration: const InputDecoration(labelText: 'min spots'),
            ),
            TextField(
              controller: _maxSpotsCtr,
              decoration: const InputDecoration(labelText: 'max spots'),
            ),
            TextField(
              controller: _rarityCtr,
              decoration: const InputDecoration(labelText: 'min rarity'),
            ),
            TextField(
              controller: _matchCtr,
              decoration: const InputDecoration(labelText: 'min tag match'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _apply,
              child: const Text('Apply'),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _packs.length,
                      itemBuilder: (_, i) => ListTile(title: Text(_packs[i])),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
