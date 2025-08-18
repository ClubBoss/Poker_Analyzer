import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_progress_service.dart';
import '../services/track_reward_preview_service.dart';
import 'skill_tree_path_screen.dart';

class SkillTreeTrackIntroScreen extends StatefulWidget {
  final String trackId;
  const SkillTreeTrackIntroScreen({super.key, required this.trackId});

  @override
  State<SkillTreeTrackIntroScreen> createState() =>
      _SkillTreeTrackIntroScreenState();
}

class _SkillTreeTrackIntroScreenState extends State<SkillTreeTrackIntroScreen> {
  String _title = '';
  String _description = '';
  bool _loading = true;
  late final Future<TrackRewardPreviewService> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = TrackRewardPreviewService.create();
    _load();
  }

  Future<void> _load() async {
    await SkillTreeLibraryService.instance.reload();
    final res = SkillTreeLibraryService.instance.getTrack(widget.trackId);
    final tree = res?.tree;
    if (tree != null && tree.nodes.isNotEmpty) {
      _title = tree.roots.isNotEmpty
          ? tree.roots.first.title
          : tree.nodes.values.first.title;
    } else {
      _title = widget.trackId;
    }
    // Placeholder description until YAML provides it
    _description = 'Пройдите этапы, чтобы освоить навык.';
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    await SkillTreeTrackProgressService().markStarted(widget.trackId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreePathScreen(trackId: widget.trackId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/learning_intro.svg',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 24),
              Text(
                _title,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _description,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              FutureBuilder<TrackRewardPreviewService>(
                future: _previewFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      snapshot.data!.buildPreviewCard(widget.trackId),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
              ElevatedButton(onPressed: _start, child: const Text('Начать')),
            ],
          ),
        ),
      ),
    );
  }
}
