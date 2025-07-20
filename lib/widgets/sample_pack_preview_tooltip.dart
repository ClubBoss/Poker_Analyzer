import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Small info icon with tooltip guiding users to preview a sample pack.
class SamplePackPreviewTooltip extends StatelessWidget {
  const SamplePackPreviewTooltip({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Tooltip(
      message: l.samplePreviewHint,
      child: const Icon(Icons.info_outline, color: Colors.orangeAccent),
    );
  }
}
