part of 'template_library_core.dart';

extension TemplateLibraryOverlay on _TemplateLibraryScreenState {
  Future<bool> _maybeAutoSample(v2.TrainingPackTemplate t) async {
    if (_autoSampled.contains(t.id)) return false;
    if (t.spots.length <= 30) return false;
    if (_previewCompleted.contains(t.id)) return false;
    final stat = await TrainingPackStatsService.getStats(t.id);
    if (stat != null) return false;

    _autoSampled.add(t.id);
    const sampler = TrainingPackSampler();
    final sample = sampler.sample(t);
    final preview = TrainingPackTemplate.fromJson(sample.toJson());
    preview.meta['samplePreview'] = true;
    await context
        .read<TrainingSessionService>()
        .startSession(preview, persist: false);
    if (!context.mounted) return true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(
          template: preview,
          original: preview,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.autoSampleToast)),
    );
    return true;
  }

  Future<void> _onLockedPackTap(TrainingPackTemplate t, String? reason) async {
    final l = AppLocalizations.of(context)!;
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);
    if (previewRequired) {
      final tplV2 = TrainingPackTemplateV2.fromTemplate(
        t,
        type: const TrainingTypeEngine().detectTrainingType(t),
      );
      if (await _maybeAutoSample(tplV2)) return;
    }
    if (previewRequired) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(l.samplePreviewPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(_, true),
              child: Text(l.previewSample),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        const sampler = TrainingPackSampler();
        final tplV2 = TrainingPackTemplateV2.fromTemplate(
          t,
          type: const TrainingTypeEngine().detectTrainingType(t),
        );
        final sample = sampler.sample(tplV2);
        final preview = TrainingPackTemplate.fromJson(sample.toJson());
        preview.meta['samplePreview'] = true;
        await context
            .read<TrainingSessionService>()
            .startSession(preview, persist: false);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPackPlayScreen(
              template: preview,
              original: preview,
            ),
          ),
        );
        return;
      }
    }
    if (reason != null) _showUnlockHint(reason);
  }

  Future<void> _onLockedLibraryPackTap(
      v2.TrainingPackTemplate t, String? reason) async {
    final l = AppLocalizations.of(context)!;
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);
    if (previewRequired && await _maybeAutoSample(t)) return;
    if (previewRequired) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(l.samplePreviewPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(_, true),
              child: Text(l.previewSample),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        const sampler = TrainingPackSampler();
        final sample = sampler.sample(t);
        final preview = TrainingPackTemplate.fromJson(sample.toJson());
        preview.meta['samplePreview'] = true;
        await context
            .read<TrainingSessionService>()
            .startSession(preview, persist: false);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPackPlayScreen(
              template: preview,
              original: preview,
            ),
          ),
        );
        return;
      }
    }
    if (reason != null) _showUnlockHint(reason);
  }

}
