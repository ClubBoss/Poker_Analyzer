import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'png_exporter.dart';
import 'reward_card_style_tuner_service.dart';
import 'skill_tree_library_service.dart';

/// Renders a shareable reward card for completed tracks.
class RewardCardRendererService {
  final SkillTreeLibraryService library;
  final SharedPreferences prefs;
  final RewardCardStyleTunerService styleTuner;

  RewardCardRendererService._({
    required this.library,
    required this.prefs,
    required this.styleTuner,
  });

  /// Creates an instance using [library] and [prefs] or default singletons.
  static Future<RewardCardRendererService> create({
    SkillTreeLibraryService? library,
    SharedPreferences? prefs,
    RewardCardStyleTunerService? styleTuner,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final l = library ?? SkillTreeLibraryService.instance;
    final t = styleTuner ?? RewardCardStyleTunerService();
    return RewardCardRendererService._(library: l, prefs: p, styleTuner: t);
  }

  /// Builds a styled reward card widget for [trackId].
  Widget buildCard(String trackId) {
    final title = _resolveTrackTitle(trackId);
    final completed = prefs.getBool('reward_granted_$trackId') ?? false;
    final style = styleTuner.getStyle(trackId);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(style.icon, size: 48, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Poker Analyzer',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (completed)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  style.badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Exports the reward card for [trackId] as a PNG image.
  Future<Uint8List> exportImage(String trackId) async {
    final img = await PngExporter.exportWidget(buildCard(trackId));
    return img ?? Uint8List(0);
  }

  String _resolveTrackTitle(String trackId) {
    final track = library.getTrack(trackId)?.tree;
    if (track == null) return trackId;
    if (track.roots.isNotEmpty) return track.roots.first.title;
    if (track.nodes.isNotEmpty) return track.nodes.values.first.title;
    return trackId;
  }
}
