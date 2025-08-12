// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get favorites => 'Favoris';

  @override
  String get recommended => 'Recommandé';

  @override
  String get starterPacks => 'Packs de démarrage';

  @override
  String get builtInPacks => 'Packs intégrés';

  @override
  String get yourPacks => 'Vos packs';

  @override
  String get recentPacks => 'Pratiqué récemment';

  @override
  String get popularPacks => '🔥 Populaire';

  @override
  String get newPacks => '🆕 Nouveau';

  @override
  String get starterBadge => 'Débutant';

  @override
  String get newBadge => 'Nouveau';

  @override
  String get masteredBadge => '✅ Maîtrisé';

  @override
  String get hands => 'mains';

  @override
  String get startTraining => 'Commencer l\'entraînement';

  @override
  String get lastTrained => 'Dernier entraînement';

  @override
  String get needsPractice => 'Nécessite de la pratique';

  @override
  String get reviewMistakes => 'Revoir les erreurs';

  @override
  String get reviewMistakesOnly => 'Seulement les erreurs';

  @override
  String percentLabel(Object value) {
    return '$value %';
  }
  @override
  String get starter_packs_title => 'Pack de démarrage';

  @override
  String get starter_packs_subtitle => 'Commencez l'entraînement en un clic';

  @override
  String get starter_packs_start => 'Démarrer';

  @override
  String get starter_packs_continue => 'Continuer';

  @override
  String get starter_packs_choose => 'Choisir le pack';


  @override
  String accuracySemantics(Object value) {
    return 'Précision $value pour cent';
  }

  @override
  String get sortProgress => 'Progression';

  @override
  String get sortNewest => 'Le plus récent';

  @override
  String get sortMostHands => 'Le plus de mains';

  @override
  String get sortName => 'Nom A–Z';

  @override
  String get noMistakesLeft => 'Toutes les erreurs sont déjà corrigées !';

  @override
  String get filterMistakes => 'Erreurs';

  @override
  String get sortInProgress => 'En cours';

  @override
  String get packPushFold12 => 'Push/Fold 12BB (Sans Ante)';

  @override
  String get packPushFold15 => 'Push/Fold 15BB (Sans Ante)';

  @override
  String get packPushFold10 => 'Push/Fold 10BB (Sans Ante)';

  @override
  String get packPushFold20 => 'Push/Fold 20BB (Sans Ante)';

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
  String get generateSpots => 'Générer des spots';

  @override
  String get noContent => 'Pas de contenu';

  @override
  String get unsupportedSpot => 'Situation non prise en charge';

  @override
  String get startTrainingSessionPrompt =>
      'Commencer la session d\'entraînement maintenant ?';

  @override
  String get trainingSummary => 'Résumé d\'entraînement';

  @override
  String get noMistakes => 'Aucune erreur';

  @override
  String get repeatMistakes => 'Répéter les erreurs';

  @override
  String get backToLibrary => 'Retour à la bibliothèque';

  @override
  String get recommendedPacks => 'Packs recommandés';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String get masteredPacks => 'Packs maîtrisés';

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
  String get sortLabel => 'Tri :';

  @override
  String get sortPopular => 'Populaires d\'abord';

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
  String get packOfDay => '🎲 Pack du Jour';

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
}
