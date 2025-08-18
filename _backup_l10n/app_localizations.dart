import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
  ];

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @starterPacks.
  ///
  /// In en, this message translates to:
  /// **'Starter Packs'**
  String get starterPacks;

  /// No description provided for @builtInPacks.
  ///
  /// In en, this message translates to:
  /// **'Built-in Packs'**
  String get builtInPacks;

  /// No description provided for @yourPacks.
  ///
  /// In en, this message translates to:
  /// **'Your Packs'**
  String get yourPacks;

  /// No description provided for @recentPacks.
  ///
  /// In en, this message translates to:
  /// **'Recently Practised'**
  String get recentPacks;

  /// No description provided for @popularPacks.
  ///
  /// In en, this message translates to:
  /// **'🔥 Popular'**
  String get popularPacks;

  /// No description provided for @newPacks.
  ///
  /// In en, this message translates to:
  /// **'🆕 New'**
  String get newPacks;

  /// No description provided for @starterBadge.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starterBadge;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @masteredBadge.
  ///
  /// In en, this message translates to:
  /// **'✅ Mastered'**
  String get masteredBadge;

  /// No description provided for @hands.
  ///
  /// In en, this message translates to:
  /// **'hands'**
  String get hands;

  /// No description provided for @startTraining.
  ///
  /// In en, this message translates to:
  /// **'Start training'**
  String get startTraining;

  /// No description provided for @lastTrained.
  ///
  /// In en, this message translates to:
  /// **'Last trained'**
  String get lastTrained;

  /// No description provided for @needsPractice.
  ///
  /// In en, this message translates to:
  /// **'Needs Practice'**
  String get needsPractice;

  /// No description provided for @reviewMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review Mistakes'**
  String get reviewMistakes;

  /// No description provided for @reviewMistakesOnly.
  ///
  /// In en, this message translates to:
  /// **'Review Mistakes Only'**
  String get reviewMistakesOnly;

  /// No description provided for @percentLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} %'**
  String percentLabel(Object value);

  /// No description provided for @starter_packs_title.
  ///
  /// In en, this message translates to:
  /// **'Starter pack'**
  String get starter_packs_title;

  /// No description provided for @starter_packs_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start training instantly'**
  String get starter_packs_subtitle;

  /// No description provided for @starter_packs_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get starter_packs_start;

  /// No description provided for @starter_packs_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get starter_packs_continue;

  /// No description provided for @starter_packs_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose pack'**
  String get starter_packs_choose;

  /// No description provided for @accuracySemantics.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {value} percent'**
  String accuracySemantics(Object value);

  /// No description provided for @sortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get sortProgress;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortMostHands.
  ///
  /// In en, this message translates to:
  /// **'Most Hands'**
  String get sortMostHands;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get sortName;

  /// No description provided for @noMistakesLeft.
  ///
  /// In en, this message translates to:
  /// **'All mistakes already fixed!'**
  String get noMistakesLeft;

  /// No description provided for @filterMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get filterMistakes;

  /// No description provided for @sortInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get sortInProgress;

  /// No description provided for @packPushFold12.
  ///
  /// In en, this message translates to:
  /// **'Push/Fold 12BB (No Ante)'**
  String get packPushFold12;

  /// No description provided for @packPushFold15.
  ///
  /// In en, this message translates to:
  /// **'Push/Fold 15BB (No Ante)'**
  String get packPushFold15;

  /// No description provided for @packPushFold10.
  ///
  /// In en, this message translates to:
  /// **'Push/Fold 10BB (No Ante)'**
  String get packPushFold10;

  /// No description provided for @packPushFold20.
  ///
  /// In en, this message translates to:
  /// **'Push/Fold 20BB (No Ante)'**
  String get packPushFold20;

  /// No description provided for @presetBtn10bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 10BB Push/Fold'**
  String get presetBtn10bb;

  /// No description provided for @presetBtn11bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 11BB Push/Fold'**
  String get presetBtn11bb;

  /// No description provided for @presetBtn12bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 12BB Push/Fold'**
  String get presetBtn12bb;

  /// No description provided for @presetBtn13bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 13BB Push/Fold'**
  String get presetBtn13bb;

  /// No description provided for @presetBtn14bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 14BB Push/Fold'**
  String get presetBtn14bb;

  /// No description provided for @presetBtn15bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 15BB Push/Fold'**
  String get presetBtn15bb;

  /// No description provided for @presetBtn16bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 16BB Push/Fold'**
  String get presetBtn16bb;

  /// No description provided for @presetBtn17bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 17BB Push/Fold'**
  String get presetBtn17bb;

  /// No description provided for @presetBtn18bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 18BB Push/Fold'**
  String get presetBtn18bb;

  /// No description provided for @presetBtn19bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 19BB Push/Fold'**
  String get presetBtn19bb;

  /// No description provided for @presetBtn20bb.
  ///
  /// In en, this message translates to:
  /// **'BTN 20BB Push/Fold'**
  String get presetBtn20bb;

  /// No description provided for @presetSb10bb.
  ///
  /// In en, this message translates to:
  /// **'SB 10BB Push/Fold'**
  String get presetSb10bb;

  /// No description provided for @presetSb11bb.
  ///
  /// In en, this message translates to:
  /// **'SB 11BB Push/Fold'**
  String get presetSb11bb;

  /// No description provided for @presetSb12bb.
  ///
  /// In en, this message translates to:
  /// **'SB 12BB Push/Fold'**
  String get presetSb12bb;

  /// No description provided for @presetSb13bb.
  ///
  /// In en, this message translates to:
  /// **'SB 13BB Push/Fold'**
  String get presetSb13bb;

  /// No description provided for @presetSb14bb.
  ///
  /// In en, this message translates to:
  /// **'SB 14BB Push/Fold'**
  String get presetSb14bb;

  /// No description provided for @presetSb15bb.
  ///
  /// In en, this message translates to:
  /// **'SB 15BB Push/Fold'**
  String get presetSb15bb;

  /// No description provided for @presetSb16bb.
  ///
  /// In en, this message translates to:
  /// **'SB 16BB Push/Fold'**
  String get presetSb16bb;

  /// No description provided for @presetSb17bb.
  ///
  /// In en, this message translates to:
  /// **'SB 17BB Push/Fold'**
  String get presetSb17bb;

  /// No description provided for @presetSb18bb.
  ///
  /// In en, this message translates to:
  /// **'SB 18BB Push/Fold'**
  String get presetSb18bb;

  /// No description provided for @presetSb19bb.
  ///
  /// In en, this message translates to:
  /// **'SB 19BB Push/Fold'**
  String get presetSb19bb;

  /// No description provided for @presetSb20bb.
  ///
  /// In en, this message translates to:
  /// **'SB 20BB Push/Fold'**
  String get presetSb20bb;

  /// No description provided for @generateSpots.
  ///
  /// In en, this message translates to:
  /// **'Generate spots'**
  String get generateSpots;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @unsupportedSpot.
  ///
  /// In en, this message translates to:
  /// **'Unsupported spot'**
  String get unsupportedSpot;

  /// No description provided for @startTrainingSessionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start training session now?'**
  String get startTrainingSessionPrompt;

  /// No description provided for @trainingSummary.
  ///
  /// In en, this message translates to:
  /// **'Training Summary'**
  String get trainingSummary;

  /// No description provided for @noMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes'**
  String get noMistakes;

  /// No description provided for @repeatMistakes.
  ///
  /// In en, this message translates to:
  /// **'Repeat Mistakes'**
  String get repeatMistakes;

  /// No description provided for @backToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to Library'**
  String get backToLibrary;

  /// No description provided for @recommendedPacks.
  ///
  /// In en, this message translates to:
  /// **'Recommended packs'**
  String get recommendedPacks;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @masteredPacks.
  ///
  /// In en, this message translates to:
  /// **'Mastered packs'**
  String get masteredPacks;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @accuracyPercent.
  ///
  /// In en, this message translates to:
  /// **'Accuracy %'**
  String get accuracyPercent;

  /// No description provided for @ev.
  ///
  /// In en, this message translates to:
  /// **'EV'**
  String get ev;

  /// No description provided for @icm.
  ///
  /// In en, this message translates to:
  /// **'ICM'**
  String get icm;

  /// No description provided for @spotDetails.
  ///
  /// In en, this message translates to:
  /// **'Spot Details'**
  String get spotDetails;

  /// No description provided for @heroPosition.
  ///
  /// In en, this message translates to:
  /// **'Hero position: {pos}'**
  String heroPosition(Object pos);

  /// No description provided for @heroCards.
  ///
  /// In en, this message translates to:
  /// **'Hero cards: {cards}'**
  String heroCards(Object cards);

  /// No description provided for @boardLabel.
  ///
  /// In en, this message translates to:
  /// **'Board: {cards}'**
  String boardLabel(Object cards);

  /// No description provided for @yourAction.
  ///
  /// In en, this message translates to:
  /// **'Your action: {action}'**
  String yourAction(Object action);

  /// No description provided for @evIcm.
  ///
  /// In en, this message translates to:
  /// **'EV {ev}  ICM {icm}'**
  String evIcm(Object ev, Object icm);

  /// No description provided for @packCreated.
  ///
  /// In en, this message translates to:
  /// **'Pack \"{name}\" created'**
  String packCreated(Object name);

  /// No description provided for @resetPackPrompt.
  ///
  /// In en, this message translates to:
  /// **'Reset progress for \'{name}\'?'**
  String resetPackPrompt(Object name);

  /// No description provided for @resetStagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Reset stage \'{name}\'?'**
  String resetStagePrompt(Object name);

  /// No description provided for @resetStage.
  ///
  /// In en, this message translates to:
  /// **'Reset Stage'**
  String get resetStage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @playerType.
  ///
  /// In en, this message translates to:
  /// **'Player Type'**
  String get playerType;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// No description provided for @fold.
  ///
  /// In en, this message translates to:
  /// **'Fold'**
  String get fold;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @raise.
  ///
  /// In en, this message translates to:
  /// **'Raise'**
  String get raise;

  /// No description provided for @push.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @entrants.
  ///
  /// In en, this message translates to:
  /// **'Entrants'**
  String get entrants;

  /// No description provided for @gameType.
  ///
  /// In en, this message translates to:
  /// **'Game Type'**
  String get gameType;

  /// No description provided for @holdemNl.
  ///
  /// In en, this message translates to:
  /// **'Hold\'em NL'**
  String get holdemNl;

  /// No description provided for @omahaPl.
  ///
  /// In en, this message translates to:
  /// **'Omaha PL'**
  String get omahaPl;

  /// No description provided for @otherGameType.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGameType;

  /// No description provided for @spotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Spots: {value}'**
  String spotsLabel(Object value);

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {value}%'**
  String accuracyLabel(Object value);

  /// No description provided for @evBb.
  ///
  /// In en, this message translates to:
  /// **'EV: {value} BB'**
  String evBb(Object value);

  /// No description provided for @icmLabel.
  ///
  /// In en, this message translates to:
  /// **'ICM: {value}'**
  String icmLabel(Object value);

  /// No description provided for @exportWeaknessReport.
  ///
  /// In en, this message translates to:
  /// **'Export Weakness Report'**
  String get exportWeaknessReport;

  /// No description provided for @packsShown.
  ///
  /// In en, this message translates to:
  /// **'Shown {count} packs'**
  String packsShown(Object count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sorting:'**
  String get sortLabel;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular first'**
  String get sortPopular;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating (High → Low)'**
  String get sortRating;

  /// No description provided for @sortCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage (High → Low)'**
  String get sortCoverage;

  /// No description provided for @filtersSelected.
  ///
  /// In en, this message translates to:
  /// **'Filters: {count} selected'**
  String filtersSelected(Object count);

  /// No description provided for @filtersNone.
  ///
  /// In en, this message translates to:
  /// **'Filters: none'**
  String get filtersNone;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @packsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Packs Completed'**
  String get packsCompleted;

  /// No description provided for @averageAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Avg Accuracy'**
  String get averageAccuracy;

  /// No description provided for @averageEv.
  ///
  /// In en, this message translates to:
  /// **'Avg EV'**
  String get averageEv;

  /// No description provided for @pinnedPacks.
  ///
  /// In en, this message translates to:
  /// **'📌 Pinned Templates'**
  String get pinnedPacks;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get dailyStreak;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @weakAreas.
  ///
  /// In en, this message translates to:
  /// **'Weak Areas'**
  String get weakAreas;

  /// No description provided for @packOfDay.
  ///
  /// In en, this message translates to:
  /// **'🎲 Pack of the Day'**
  String get packOfDay;

  /// No description provided for @levelGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Level Goal'**
  String get levelGoalTitle;

  /// No description provided for @samplePreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Try a sample first to explore this pack!'**
  String get samplePreviewHint;

  /// No description provided for @samplePreviewPrompt.
  ///
  /// In en, this message translates to:
  /// **'This pack is large. Preview a quick sample first?'**
  String get samplePreviewPrompt;

  /// No description provided for @previewSample.
  ///
  /// In en, this message translates to:
  /// **'Preview Sample'**
  String get previewSample;

  /// No description provided for @autoSampleToast.
  ///
  /// In en, this message translates to:
  /// **'Quick preview launched automatically for faster start.'**
  String get autoSampleToast;

  /// No description provided for @plannerBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String plannerBadge(Object count);

  /// No description provided for @unfinishedSession.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished session'**
  String get unfinishedSession;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @mistakeBoosterReinforced.
  ///
  /// In en, this message translates to:
  /// **'Reinforced: {count} tags'**
  String mistakeBoosterReinforced(Object count);

  /// No description provided for @mistakeBoosterRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered: {count} tags'**
  String mistakeBoosterRecovered(Object count);

  /// No description provided for @quickstartL3.
  ///
  /// In en, this message translates to:
  /// **'Quickstart L3'**
  String get quickstartL3;

  /// No description provided for @desktopOnly.
  ///
  /// In en, this message translates to:
  /// **'Desktop only'**
  String get desktopOnly;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @openReport.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get openReport;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @presetWillBeUsed.
  ///
  /// In en, this message translates to:
  /// **'Preset will be used'**
  String get presetWillBeUsed;

  /// No description provided for @reportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Report is empty'**
  String get reportEmpty;

  /// No description provided for @abDiff.
  ///
  /// In en, this message translates to:
  /// **'A/B diff'**
  String get abDiff;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @weightsPreset.
  ///
  /// In en, this message translates to:
  /// **'Weights preset'**
  String get weightsPreset;

  /// No description provided for @weightsJson.
  ///
  /// In en, this message translates to:
  /// **'Weights JSON'**
  String get weightsJson;

  /// No description provided for @invalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON'**
  String get invalidJson;

  /// No description provided for @recentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get recentRuns;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// No description provided for @reRun.
  ///
  /// In en, this message translates to:
  /// **'Re-run'**
  String get reRun;

  /// No description provided for @pickTwoRuns.
  ///
  /// In en, this message translates to:
  /// **'Pick two runs'**
  String get pickTwoRuns;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection'**
  String get noSelection;

  /// No description provided for @rootKeys.
  ///
  /// In en, this message translates to:
  /// **'Root keys'**
  String get rootKeys;

  /// No description provided for @arrayLengths.
  ///
  /// In en, this message translates to:
  /// **'Array lengths'**
  String get arrayLengths;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all runs? This action cannot be undone.'**
  String get confirmClear;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reveal;

  /// No description provided for @csvSaved.
  ///
  /// In en, this message translates to:
  /// **'CSV saved'**
  String get csvSaved;

  /// No description provided for @delta.
  ///
  /// In en, this message translates to:
  /// **'Δ'**
  String get delta;

  /// No description provided for @args.
  ///
  /// In en, this message translates to:
  /// **'Args'**
  String get args;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
