import 'package:flutter/material.dart';

import '../main.dart';
import '../models/theory_pack_model.dart';
import '../screens/theory_pack_reader_screen.dart';

/// Helper to open a [TheoryPackModel] in reader mode.
class TheoryTrainingLauncher {
  TheoryTrainingLauncher();

  /// Pushes [pack] onto the navigation stack.
  Future<void> launch(TheoryPackModel pack) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TheoryPackReaderScreen(pack: pack, stageId: pack.id),
      ),
    );
  }
}
