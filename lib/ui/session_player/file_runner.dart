import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'decoders.dart';
import 'mvs_player.dart';
import 'models.dart';

class PlayFromFilePage extends StatelessWidget {
  final String path;
  const PlayFromFilePage({super.key, required this.path});

  Future<List<UiSpot>> _load() async {
    final jsonStr = await File(path).readAsString();
    final root = jsonDecode(jsonStr);
    final kind = detectSessionKind(root);
    switch (kind) {
      case 'l2':
        return decodeL2SessionJson(jsonStr);
      case 'l3':
        return await decodeL3SessionJson(jsonStr,
            baseDir: File(path).parent.path);
      case 'l4':
        return decodeL4IcmSessionJson(jsonStr);
      default:
        throw Exception('unknown session kind');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UiSpot>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final spots = snap.data ?? [];
        return MvsSessionPlayer(spots: spots);
      },
    );
  }
}
