import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../utils/snackbar_util.dart';

/// Button for copying or sharing a direct link to a learning path stage preview.
class StageShareButton extends StatelessWidget {
  final LearningPathTemplateV2 path;
  final LearningPathStageModel stage;

  const StageShareButton({
    super.key,
    required this.path,
    required this.stage,
  });

  String get _link =>
      'https://pokeranalyzer.app/path/${path.id}/stage/${stage.id}';

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _link));
    await Share.share(_link);
    SnackbarUtil.showMessage(context, Localizations.localeOf(context).languageCode == 'ru'
              ? 'Ссылка скопирована'
              : 'Link copied',);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.link),
      tooltip: Localizations.localeOf(context).languageCode == 'ru'
          ? 'Копировать ссылку'
          : 'Copy link',
      onPressed: () => _share(context),
    );
  }
}
