// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get favorites => 'Favoritos';

  @override
  String get recommended => 'Recomendado';

  @override
  String get starterPacks => 'Paquetes iniciales';

  @override
  String get builtInPacks => 'Paquetes integrados';

  @override
  String get yourPacks => 'Tus paquetes';

  @override
  String get recentPacks => 'Practicado recientemente';

  @override
  String get popularPacks => '🔥 Populares';

  @override
  String get newPacks => '🆕 Nuevo';

  @override
  String get starterBadge => 'Principiante';

  @override
  String get newBadge => 'Nuevo';

  @override
  String get masteredBadge => '✅ Dominar';

  @override
  String get hands => 'manos';

  @override
  String get startTraining => 'Iniciar entrenamiento';

  @override
  String get lastTrained => 'Último entrenamiento';

  @override
  String get needsPractice => 'Necesita práctica';

  @override
  String get reviewMistakes => 'Revisar errores';

  @override
  String get reviewMistakesOnly => 'Solo errores';

  @override
  String percentLabel(Object value) {
    return '$value %';
  }

  @override
  String get starter_packs_title => 'Paquete inicial';

  @override
  String get starter_packs_subtitle => 'Comienza a entrenar al instante';

  @override
  String get starter_packs_start => 'Empezar';

  @override
  String get starter_packs_continue => 'Continuar';

  @override
  String get starter_packs_choose => 'Elegir pack';

  @override
  String accuracySemantics(Object value) {
    return 'Precisión $value por ciento';
  }

  @override
  String get sortProgress => 'Progreso';

  @override
  String get sortNewest => 'Más nuevo';

  @override
  String get sortMostHands => 'Más manos';

  @override
  String get sortName => 'Nombre A–Z';

  @override
  String get noMistakesLeft => '¡Todos los errores ya corregidos!';

  @override
  String get filterMistakes => 'Errores';

  @override
  String get sortInProgress => 'En progreso';

  @override
  String get packPushFold12 => 'Push/Fold 12BB (Sin Ante)';

  @override
  String get packPushFold15 => 'Push/Fold 15BB (Sin Ante)';

  @override
  String get packPushFold10 => 'Push/Fold 10BB (Sin Ante)';

  @override
  String get packPushFold20 => 'Push/Fold 20BB (Sin Ante)';

  @override
  String get presetBtn10bb => 'BTN 10BB Push/Fold';

  @override
  String get presetBtn11bb => 'BTN 11BB Push/Fold';

  @override
  String get presetBtn12bb => 'BTN 12BB Push/Fold';

  @override
  String get presetBtn13bb => 'BTN 13BB Push/Fold';

  @override
  String get presetBtn14bb => 'BTN 14BB Push/Fold';

  @override
  String get presetBtn15bb => 'BTN 15BB Push/Fold';

  @override
  String get presetBtn16bb => 'BTN 16BB Push/Fold';

  @override
  String get presetBtn17bb => 'BTN 17BB Push/Fold';

  @override
  String get presetBtn18bb => 'BTN 18BB Push/Fold';

  @override
  String get presetBtn19bb => 'BTN 19BB Push/Fold';

  @override
  String get presetBtn20bb => 'BTN 20BB Push/Fold';

  @override
  String get presetSb10bb => 'SB 10BB Push/Fold';

  @override
  String get presetSb11bb => 'SB 11BB Push/Fold';

  @override
  String get presetSb12bb => 'SB 12BB Push/Fold';

  @override
  String get presetSb13bb => 'SB 13BB Push/Fold';

  @override
  String get presetSb14bb => 'SB 14BB Push/Fold';

  @override
  String get presetSb15bb => 'SB 15BB Push/Fold';

  @override
  String get presetSb16bb => 'SB 16BB Push/Fold';

  @override
  String get presetSb17bb => 'SB 17BB Push/Fold';

  @override
  String get presetSb18bb => 'SB 18BB Push/Fold';

  @override
  String get presetSb19bb => 'SB 19BB Push/Fold';

  @override
  String get presetSb20bb => 'SB 20BB Push/Fold';

  @override
  String get generateSpots => 'Generar manos';

  @override
  String get noContent => 'Sin contenido';

  @override
  String get unsupportedSpot => 'Situación no soportada';

  @override
  String get startTrainingSessionPrompt =>
      '¿Iniciar sesión de entrenamiento ahora?';

  @override
  String get trainingSummary => 'Resumen de entrenamiento';

  @override
  String get noMistakes => 'Sin errores';

  @override
  String get repeatMistakes => 'Repetir errores';

  @override
  String get backToLibrary => 'Volver a la biblioteca';

  @override
  String get recommendedPacks => 'Paquetes recomendados';

  @override
  String get recommendedForYou => 'Recomendado para ti';

  @override
  String get masteredPacks => 'Paquetes dominados';

  @override
  String get dailyGoals => 'Daily Goals';

  @override
  String get sessions => 'Sessions';

  @override
  String get accuracyPercent => 'Accuracy %';

  @override
  String get ev => 'EV';

  @override
  String get icm => 'ICM';

  @override
  String get spotDetails => 'Spot Details';

  @override
  String heroPosition(Object pos) {
    return 'Hero position: $pos';
  }

  @override
  String heroCards(Object cards) {
    return 'Hero cards: $cards';
  }

  @override
  String boardLabel(Object cards) {
    return 'Board: $cards';
  }

  @override
  String yourAction(Object action) {
    return 'Your action: $action';
  }

  @override
  String evIcm(Object ev, Object icm) {
    return 'EV $ev  ICM $icm';
  }

  @override
  String packCreated(Object name) {
    return 'Pack \"$name\" created';
  }

  @override
  String resetPackPrompt(Object name) {
    return 'Reset progress for \'$name\'?';
  }

  @override
  String resetStagePrompt(Object name) {
    return 'Reset stage \'$name\'?';
  }

  @override
  String get resetStage => 'Reset Stage';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get playerType => 'Player Type';

  @override
  String get selectAction => 'Select Action';

  @override
  String get fold => 'Fold';

  @override
  String get call => 'Call';

  @override
  String get raise => 'Raise';

  @override
  String get push => 'Push';

  @override
  String get amount => 'Amount';

  @override
  String get confirm => 'Confirm';

  @override
  String get clear => 'Clear';

  @override
  String get ok => 'OK';

  @override
  String get entrants => 'Entrants';

  @override
  String get gameType => 'Game Type';

  @override
  String get holdemNl => 'Hold\'em NL';

  @override
  String get omahaPl => 'Omaha PL';

  @override
  String get otherGameType => 'Other';

  @override
  String spotsLabel(Object value) {
    return 'Spots: $value';
  }

  @override
  String accuracyLabel(Object value) {
    return 'Accuracy: $value%';
  }

  @override
  String evBb(Object value) {
    return 'EV: $value BB';
  }

  @override
  String icmLabel(Object value) {
    return 'ICM: $value';
  }

  @override
  String get exportWeaknessReport => 'Export Weakness Report';

  @override
  String packsShown(Object count) {
    return 'Shown $count packs';
  }

  @override
  String get noResults => 'No results';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get sortLabel => 'Orden:';

  @override
  String get sortPopular => 'Populares primero';

  @override
  String get sortRating => 'Rating (High → Low)';

  @override
  String get sortCoverage => 'Coverage (High → Low)';

  @override
  String filtersSelected(Object count) {
    return 'Filters: $count selected';
  }

  @override
  String get filtersNone => 'Filters: none';

  @override
  String get progress => 'Progress';

  @override
  String get packsCompleted => 'Packs Completed';

  @override
  String get averageAccuracy => 'Avg Accuracy';

  @override
  String get averageEv => 'Avg EV';

  @override
  String get dailyStreak => 'Streak';

  @override
  String get best => 'Best';

  @override
  String get pinnedPacks => '📌 Pinned Templates';

  @override
  String get weakAreas => 'Weak Areas';

  @override
  String get packOfDay => '🎲 Pack del Día';

  @override
  String get levelGoalTitle => 'Level Goal';

  @override
  String get samplePreviewHint => 'Try a sample first to explore this pack!';

  @override
  String get samplePreviewPrompt =>
      'This pack is large. Preview a quick sample first?';

  @override
  String get previewSample => 'Preview Sample';

  @override
  String get autoSampleToast =>
      'Quick preview launched automatically for faster start.';

  @override
  String plannerBadge(Object count) {
    return '$count осталось';
  }

  @override
  String get unfinishedSession => 'You have an unfinished session';

  @override
  String get resume => 'Resume';

  @override
  String mistakeBoosterReinforced(Object count) {
    return 'Reinforced: $count tags';
  }

  @override
  String mistakeBoosterRecovered(Object count) {
    return 'Recovered: $count tags';
  }

  @override
  String get quickstartL3 => 'Quickstart L3';

  @override
  String get desktopOnly => 'Solo escritorio';

  @override
  String get run => 'Run';

  @override
  String get openReport => 'Open report';

  @override
  String get viewLogs => 'View logs';

  @override
  String get retry => 'Retry';

  @override
  String get presetWillBeUsed => 'Preset will be used';

  @override
  String get reportEmpty => 'Report is empty';

  @override
  String get abDiff => 'A/B diff';

  @override
  String get export => 'Export';

  @override
  String get weightsPreset => 'Weights preset';

  @override
  String get weightsJson => 'Weights JSON';

  @override
  String get recentRuns => 'Recent runs';

  @override
  String get open => 'Open';

  @override
  String get logs => 'Logs';

  @override
  String get folder => 'Folder';

  @override
  String get copyPath => 'Copy path';

  @override
  String get reRun => 'Re-run';

  @override
  String get pickTwoRuns => 'Pick two runs';

  @override
  String get compare => 'Compare';

  @override
  String get noSelection => 'No selection';

  @override
  String get rootKeys => 'Root keys';

  @override
  String get arrayLengths => 'Array lengths';
}
