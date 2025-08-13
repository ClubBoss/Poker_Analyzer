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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ru')
  ];

  /// No description provided for @favorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favorites;

  /// No description provided for @recommended.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендовано'**
  String get recommended;

  /// No description provided for @starterPacks.
  ///
  /// In ru, this message translates to:
  /// **'Стартовые паки'**
  String get starterPacks;

  /// No description provided for @builtInPacks.
  ///
  /// In ru, this message translates to:
  /// **'Встроенные паки'**
  String get builtInPacks;

  /// No description provided for @yourPacks.
  ///
  /// In ru, this message translates to:
  /// **'Ваши паки'**
  String get yourPacks;

  /// No description provided for @recentPacks.
  ///
  /// In ru, this message translates to:
  /// **'Недавняя практика'**
  String get recentPacks;

  /// No description provided for @popularPacks.
  ///
  /// In ru, this message translates to:
  /// **'🔥 Популярное'**
  String get popularPacks;

  /// No description provided for @newPacks.
  ///
  /// In ru, this message translates to:
  /// **'🆕 Новые'**
  String get newPacks;

  /// No description provided for @starterBadge.
  ///
  /// In ru, this message translates to:
  /// **'Стартер'**
  String get starterBadge;

  /// No description provided for @newBadge.
  ///
  /// In ru, this message translates to:
  /// **'Новое'**
  String get newBadge;

  /// No description provided for @masteredBadge.
  ///
  /// In ru, this message translates to:
  /// **'✅ Освоено'**
  String get masteredBadge;

  /// No description provided for @hands.
  ///
  /// In ru, this message translates to:
  /// **'рук'**
  String get hands;

  /// No description provided for @startTraining.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку'**
  String get startTraining;

  /// No description provided for @lastTrained.
  ///
  /// In ru, this message translates to:
  /// **'Последняя тренировка'**
  String get lastTrained;

  /// No description provided for @needsPractice.
  ///
  /// In ru, this message translates to:
  /// **'Требует практики'**
  String get needsPractice;

  /// No description provided for @reviewMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Разбор ошибок'**
  String get reviewMistakes;

  /// No description provided for @reviewMistakesOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только ошибки'**
  String get reviewMistakesOnly;

  /// No description provided for @percentLabel.
  ///
  /// In ru, this message translates to:
  /// **'{value} %'**
  String percentLabel(Object value);

  /// No description provided for @starter_packs_title.
  ///
  /// In ru, this message translates to:
  /// **'Стартовый пак'**
  String get starter_packs_title;

  /// No description provided for @starter_packs_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Начните тренировку одним нажатием'**
  String get starter_packs_subtitle;

  /// No description provided for @starter_packs_start.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get starter_packs_start;

  /// No description provided for @starter_packs_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get starter_packs_continue;

  /// No description provided for @starter_packs_choose.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать пак'**
  String get starter_packs_choose;

  /// No description provided for @accuracySemantics.
  ///
  /// In ru, this message translates to:
  /// **'Точность {value} процентов'**
  String accuracySemantics(Object value);

  /// No description provided for @sortProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс'**
  String get sortProgress;

  /// No description provided for @sortNewest.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новые'**
  String get sortNewest;

  /// No description provided for @sortMostHands.
  ///
  /// In ru, this message translates to:
  /// **'Больше всего рук'**
  String get sortMostHands;

  /// No description provided for @sortName.
  ///
  /// In ru, this message translates to:
  /// **'Имя A–Я'**
  String get sortName;

  /// No description provided for @noMistakesLeft.
  ///
  /// In ru, this message translates to:
  /// **'Все ошибки уже исправлены!'**
  String get noMistakesLeft;

  /// No description provided for @filterMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Ошибки'**
  String get filterMistakes;

  /// No description provided for @sortInProgress.
  ///
  /// In ru, this message translates to:
  /// **'В процессе'**
  String get sortInProgress;

  /// No description provided for @packPushFold12.
  ///
  /// In ru, this message translates to:
  /// **'Пуш/Фолд 12ББ (без анте)'**
  String get packPushFold12;

  /// No description provided for @packPushFold15.
  ///
  /// In ru, this message translates to:
  /// **'Пуш/Фолд 15ББ (без анте)'**
  String get packPushFold15;

  /// No description provided for @packPushFold10.
  ///
  /// In ru, this message translates to:
  /// **'Пуш/Фолд 10ББ (без анте)'**
  String get packPushFold10;

  /// No description provided for @packPushFold20.
  ///
  /// In ru, this message translates to:
  /// **'Пуш/Фолд 20ББ (без анте)'**
  String get packPushFold20;

  /// No description provided for @presetBtn10bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 10BB Push/Fold'**
  String get presetBtn10bb;

  /// No description provided for @presetBtn11bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 11BB Push/Fold'**
  String get presetBtn11bb;

  /// No description provided for @presetBtn12bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 12BB Push/Fold'**
  String get presetBtn12bb;

  /// No description provided for @presetBtn13bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 13BB Push/Fold'**
  String get presetBtn13bb;

  /// No description provided for @presetBtn14bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 14BB Push/Fold'**
  String get presetBtn14bb;

  /// No description provided for @presetBtn15bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 15BB Push/Fold'**
  String get presetBtn15bb;

  /// No description provided for @presetBtn16bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 16BB Push/Fold'**
  String get presetBtn16bb;

  /// No description provided for @presetBtn17bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 17BB Push/Fold'**
  String get presetBtn17bb;

  /// No description provided for @presetBtn18bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 18BB Push/Fold'**
  String get presetBtn18bb;

  /// No description provided for @presetBtn19bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 19BB Push/Fold'**
  String get presetBtn19bb;

  /// No description provided for @presetBtn20bb.
  ///
  /// In ru, this message translates to:
  /// **'BTN 20BB Push/Fold'**
  String get presetBtn20bb;

  /// No description provided for @presetSb10bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 10BB Push/Fold'**
  String get presetSb10bb;

  /// No description provided for @presetSb11bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 11BB Push/Fold'**
  String get presetSb11bb;

  /// No description provided for @presetSb12bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 12BB Push/Fold'**
  String get presetSb12bb;

  /// No description provided for @presetSb13bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 13BB Push/Fold'**
  String get presetSb13bb;

  /// No description provided for @presetSb14bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 14BB Push/Fold'**
  String get presetSb14bb;

  /// No description provided for @presetSb15bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 15BB Push/Fold'**
  String get presetSb15bb;

  /// No description provided for @presetSb16bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 16BB Push/Fold'**
  String get presetSb16bb;

  /// No description provided for @presetSb17bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 17BB Push/Fold'**
  String get presetSb17bb;

  /// No description provided for @presetSb18bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 18BB Push/Fold'**
  String get presetSb18bb;

  /// No description provided for @presetSb19bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 19BB Push/Fold'**
  String get presetSb19bb;

  /// No description provided for @presetSb20bb.
  ///
  /// In ru, this message translates to:
  /// **'SB 20BB Push/Fold'**
  String get presetSb20bb;

  /// No description provided for @generateSpots.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать раздачи'**
  String get generateSpots;

  /// No description provided for @noContent.
  ///
  /// In ru, this message translates to:
  /// **'Нет контента'**
  String get noContent;

  /// No description provided for @unsupportedSpot.
  ///
  /// In ru, this message translates to:
  /// **'Неподдерживаемая раздача'**
  String get unsupportedSpot;

  /// No description provided for @startTrainingSessionPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку сейчас?'**
  String get startTrainingSessionPrompt;

  /// No description provided for @trainingSummary.
  ///
  /// In ru, this message translates to:
  /// **'Результаты тренировки'**
  String get trainingSummary;

  /// No description provided for @noMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Ошибок нет'**
  String get noMistakes;

  /// No description provided for @repeatMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Повторить ошибки'**
  String get repeatMistakes;

  /// No description provided for @backToLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Назад в библиотеку'**
  String get backToLibrary;

  /// No description provided for @recommendedPacks.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемые паки'**
  String get recommendedPacks;

  /// No description provided for @recommendedForYou.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендовано для вас'**
  String get recommendedForYou;

  /// No description provided for @masteredPacks.
  ///
  /// In ru, this message translates to:
  /// **'✅ Вы уже освоили'**
  String get masteredPacks;

  /// No description provided for @dailyGoals.
  ///
  /// In ru, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @sessions.
  ///
  /// In ru, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @accuracyPercent.
  ///
  /// In ru, this message translates to:
  /// **'Accuracy %'**
  String get accuracyPercent;

  /// No description provided for @ev.
  ///
  /// In ru, this message translates to:
  /// **'EV'**
  String get ev;

  /// No description provided for @icm.
  ///
  /// In ru, this message translates to:
  /// **'ICM'**
  String get icm;

  /// No description provided for @spotDetails.
  ///
  /// In ru, this message translates to:
  /// **'Spot Details'**
  String get spotDetails;

  /// No description provided for @heroPosition.
  ///
  /// In ru, this message translates to:
  /// **'Hero position: {pos}'**
  String heroPosition(Object pos);

  /// No description provided for @heroCards.
  ///
  /// In ru, this message translates to:
  /// **'Hero cards: {cards}'**
  String heroCards(Object cards);

  /// No description provided for @boardLabel.
  ///
  /// In ru, this message translates to:
  /// **'Board: {cards}'**
  String boardLabel(Object cards);

  /// No description provided for @yourAction.
  ///
  /// In ru, this message translates to:
  /// **'Your action: {action}'**
  String yourAction(Object action);

  /// No description provided for @evIcm.
  ///
  /// In ru, this message translates to:
  /// **'EV {ev}  ICM {icm}'**
  String evIcm(Object ev, Object icm);

  /// No description provided for @packCreated.
  ///
  /// In ru, this message translates to:
  /// **'Pack \"{name}\" created'**
  String packCreated(Object name);

  /// No description provided for @resetPackPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Reset progress for \'{name}\'?'**
  String resetPackPrompt(Object name);

  /// No description provided for @resetStagePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Reset stage \'{name}\'?'**
  String resetStagePrompt(Object name);

  /// No description provided for @resetStage.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить стадию'**
  String get resetStage;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @playerType.
  ///
  /// In ru, this message translates to:
  /// **'Player Type'**
  String get playerType;

  /// No description provided for @selectAction.
  ///
  /// In ru, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// No description provided for @fold.
  ///
  /// In ru, this message translates to:
  /// **'Fold'**
  String get fold;

  /// No description provided for @call.
  ///
  /// In ru, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @raise.
  ///
  /// In ru, this message translates to:
  /// **'Raise'**
  String get raise;

  /// No description provided for @push.
  ///
  /// In ru, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @amount.
  ///
  /// In ru, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @entrants.
  ///
  /// In ru, this message translates to:
  /// **'Entrants'**
  String get entrants;

  /// No description provided for @gameType.
  ///
  /// In ru, this message translates to:
  /// **'Game Type'**
  String get gameType;

  /// No description provided for @holdemNl.
  ///
  /// In ru, this message translates to:
  /// **'Hold\'em NL'**
  String get holdemNl;

  /// No description provided for @omahaPl.
  ///
  /// In ru, this message translates to:
  /// **'Omaha PL'**
  String get omahaPl;

  /// No description provided for @otherGameType.
  ///
  /// In ru, this message translates to:
  /// **'Other'**
  String get otherGameType;

  /// No description provided for @spotsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Spots: {value}'**
  String spotsLabel(Object value);

  /// No description provided for @accuracyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Accuracy: {value}%'**
  String accuracyLabel(Object value);

  /// No description provided for @evBb.
  ///
  /// In ru, this message translates to:
  /// **'EV: {value} BB'**
  String evBb(Object value);

  /// No description provided for @icmLabel.
  ///
  /// In ru, this message translates to:
  /// **'ICM: {value}'**
  String icmLabel(Object value);

  /// No description provided for @exportWeaknessReport.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать отчёт о слабых местах'**
  String get exportWeaknessReport;

  /// No description provided for @packsShown.
  ///
  /// In ru, this message translates to:
  /// **'Показано {count} паков'**
  String packsShown(Object count);

  /// No description provided for @noResults.
  ///
  /// In ru, this message translates to:
  /// **'Нет результатов'**
  String get noResults;

  /// No description provided for @resetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get resetFilters;

  /// No description provided for @sortLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка:'**
  String get sortLabel;

  /// No description provided for @sortPopular.
  ///
  /// In ru, this message translates to:
  /// **'Сначала популярные'**
  String get sortPopular;

  /// No description provided for @sortRating.
  ///
  /// In ru, this message translates to:
  /// **'Rating (High → Low)'**
  String get sortRating;

  /// No description provided for @sortCoverage.
  ///
  /// In ru, this message translates to:
  /// **'Coverage (High → Low)'**
  String get sortCoverage;

  /// No description provided for @filtersSelected.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры: {count} выбрано'**
  String filtersSelected(Object count);

  /// No description provided for @filtersNone.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры: нет'**
  String get filtersNone;

  /// No description provided for @progress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс'**
  String get progress;

  /// No description provided for @packsCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Паков завершено'**
  String get packsCompleted;

  /// No description provided for @averageAccuracy.
  ///
  /// In ru, this message translates to:
  /// **'Средняя точность'**
  String get averageAccuracy;

  /// No description provided for @averageEv.
  ///
  /// In ru, this message translates to:
  /// **'Средний EV'**
  String get averageEv;

  /// No description provided for @dailyStreak.
  ///
  /// In ru, this message translates to:
  /// **'Стрик'**
  String get dailyStreak;

  /// No description provided for @best.
  ///
  /// In ru, this message translates to:
  /// **'Рекорд'**
  String get best;

  /// No description provided for @pinnedPacks.
  ///
  /// In ru, this message translates to:
  /// **'📌 Избранные шаблоны'**
  String get pinnedPacks;

  /// No description provided for @weakAreas.
  ///
  /// In ru, this message translates to:
  /// **'Избранные категории'**
  String get weakAreas;

  /// No description provided for @packOfDay.
  ///
  /// In ru, this message translates to:
  /// **'🎲 Пак дня'**
  String get packOfDay;

  /// No description provided for @levelGoalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Цель уровня'**
  String get levelGoalTitle;

  /// No description provided for @samplePreviewHint.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте сначала образец пака'**
  String get samplePreviewHint;

  /// No description provided for @samplePreviewPrompt.
  ///
  /// In ru, this message translates to:
  /// **'This pack is large. Preview a quick sample first?'**
  String get samplePreviewPrompt;

  /// No description provided for @previewSample.
  ///
  /// In ru, this message translates to:
  /// **'Preview Sample'**
  String get previewSample;

  /// No description provided for @autoSampleToast.
  ///
  /// In ru, this message translates to:
  /// **'Quick preview launched automatically for faster start.'**
  String get autoSampleToast;

  /// No description provided for @plannerBadge.
  ///
  /// In ru, this message translates to:
  /// **'{count} осталось'**
  String plannerBadge(Object count);

  /// No description provided for @unfinishedSession.
  ///
  /// In ru, this message translates to:
  /// **'У вас есть незавершённая сессия'**
  String get unfinishedSession;

  /// No description provided for @resume.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get resume;

  /// No description provided for @mistakeBoosterReinforced.
  ///
  /// In ru, this message translates to:
  /// **'Укреплено тегов: {count}'**
  String mistakeBoosterReinforced(Object count);

  /// No description provided for @mistakeBoosterRecovered.
  ///
  /// In ru, this message translates to:
  /// **'Исправлено тегов: {count}'**
  String mistakeBoosterRecovered(Object count);

  /// No description provided for @quickstartL3.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый старт L3'**
  String get quickstartL3;

  /// No description provided for @desktopOnly.
  ///
  /// In en, this message translates to:
  /// **'Desktop only'**
  String get desktopOnly;

  /// No description provided for @run.
  ///
  /// In ru, this message translates to:
  /// **'Запустить'**
  String get run;

  /// No description provided for @openReport.
  ///
  /// In ru, this message translates to:
  /// **'Открыть отчет'**
  String get openReport;

  /// No description provided for @viewLogs.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр логов'**
  String get viewLogs;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @presetWillBeUsed.
  ///
  /// In ru, this message translates to:
  /// **'Будет использован пресет'**
  String get presetWillBeUsed;

  /// No description provided for @reportEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Отчет пуст'**
  String get reportEmpty;

  /// No description provided for @abDiff.
  ///
  /// In ru, this message translates to:
  /// **'A/B сравнение'**
  String get abDiff;

  /// No description provided for @export.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get export;

  /// No description provided for @weightsPreset.
  ///
  /// In ru, this message translates to:
  /// **'Пресет весов'**
  String get weightsPreset;

  /// No description provided for @weightsJson.
  ///
  /// In ru, this message translates to:
  /// **'JSON весов'**
  String get weightsJson;
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
        'ru'
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
      'that was used.');
}
