import '../models/v2/training_pack_preset.dart';
import '../models/v2/training_pack_template.dart';
import 'pack_generator_service.dart';
import 'training_pack_asset_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:poker_analyzer/l10n/app_localizations.dart';
import 'package:collection/collection.dart';

class TrainingPackTemplateService {
  static const _pf10Id = 'starter_pushfold_10bb';
  static const _pf12Id = 'starter_pushfold_12bb';
  static const _pf15Id = 'starter_pushfold_15bb';
  static const _pf20Id = 'starter_pushfold_20bb';

  static TrainingPackTemplate starterPushfold10bb([BuildContext? ctx]) =>
      _get(_pf10Id, ctx, (l) => l.packPushFold10);

  static TrainingPackTemplate starterPushfold12bb([BuildContext? ctx]) =>
      _get(_pf12Id, ctx, (l) => l.packPushFold12);

  static TrainingPackTemplate starterPushfold15bb([BuildContext? ctx]) =>
      _get(_pf15Id, ctx, (l) => l.packPushFold15);

  static TrainingPackTemplate starterPushfold20bb([BuildContext? ctx]) =>
      _get(_pf20Id, ctx, (l) => l.packPushFold20);

  static TrainingPackTemplate _get(
    String id,
    BuildContext? ctx,
    String Function(AppLocalizations) nameFn,
  ) {
    final tpl = TrainingPackAssetLoader.instance.getById(id);
    if (tpl == null) return TrainingPackTemplate(id: '', name: '');
    if (ctx == null) return tpl;
    return tpl.copyWith(name: nameFn(AppLocalizations.of(ctx)!));
  }

  static Future<TrainingPackTemplate> generateFromPreset(
    TrainingPackPreset preset,
  ) => PackGeneratorService.generatePackFromPreset(preset);

  static List<TrainingPackTemplate> getAllTemplates([BuildContext? ctx]) => [
    starterPushfold10bb(ctx),
    starterPushfold12bb(ctx),
    starterPushfold15bb(ctx),
    starterPushfold20bb(ctx),
    ...TrainingPackAssetLoader.instance.getAll(),
  ].where((t) => t.id.isNotEmpty).toList();

  static bool hasTemplate(String id) =>
      getAllTemplates().any((t) => t.id == id);

  static TrainingPackTemplate? getById(String id, [BuildContext? ctx]) =>
      getAllTemplates(ctx).firstWhereOrNull((t) => t.id == id);
}
