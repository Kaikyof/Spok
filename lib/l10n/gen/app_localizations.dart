import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
/// import 'gen/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appBadge.
  ///
  /// In ru, this message translates to:
  /// **'AVTOTO · КОНСОЛЬ'**
  String get appBadge;

  /// No description provided for @navSprint.
  ///
  /// In ru, this message translates to:
  /// **'Спринт'**
  String get navSprint;

  /// No description provided for @navChanges.
  ///
  /// In ru, this message translates to:
  /// **'Change\'и'**
  String get navChanges;

  /// No description provided for @navHandoff.
  ///
  /// In ru, this message translates to:
  /// **'Передача'**
  String get navHandoff;

  /// No description provided for @navEnv.
  ///
  /// In ru, this message translates to:
  /// **'Окружение'**
  String get navEnv;

  /// No description provided for @navSessions.
  ///
  /// In ru, this message translates to:
  /// **'Сессии'**
  String get navSessions;

  /// No description provided for @machineRoleLabel.
  ///
  /// In ru, this message translates to:
  /// **'РОЛЬ МАШИНЫ'**
  String get machineRoleLabel;

  /// No description provided for @machineRoleEnvVar.
  ///
  /// In ru, this message translates to:
  /// **'AVTOTO_ROLE'**
  String get machineRoleEnvVar;

  /// No description provided for @roleNotSet.
  ///
  /// In ru, this message translates to:
  /// **'роль не задана'**
  String get roleNotSet;

  /// No description provided for @roleIos.
  ///
  /// In ru, this message translates to:
  /// **'iOS-разработчик'**
  String get roleIos;

  /// No description provided for @roleAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Android-разработчик'**
  String get roleAndroid;

  /// No description provided for @roleQa.
  ///
  /// In ru, this message translates to:
  /// **'Тестировщик'**
  String get roleQa;

  /// No description provided for @roleDev.
  ///
  /// In ru, this message translates to:
  /// **'Разработчик (оба стека)'**
  String get roleDev;

  /// No description provided for @refreshTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Обновить (⌘R)'**
  String get refreshTooltip;

  /// No description provided for @updatedAt.
  ///
  /// In ru, this message translates to:
  /// **'обновлено {time}'**
  String updatedAt(String time);

  /// No description provided for @sprintNone.
  ///
  /// In ru, this message translates to:
  /// **'Нет активного спринта'**
  String get sprintNone;

  /// No description provided for @sprintTitlePrefix.
  ///
  /// In ru, this message translates to:
  /// **'Спринт: {title}'**
  String sprintTitlePrefix(String title);

  /// No description provided for @sprintSwitcherTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Переключить спринт · openspec/doc'**
  String get sprintSwitcherTooltip;

  /// No description provided for @deliveryBatch.
  ///
  /// In ru, this message translates to:
  /// **'сдача целиком (batch)'**
  String get deliveryBatch;

  /// No description provided for @deliveryPerChange.
  ///
  /// In ru, this message translates to:
  /// **'сдача по change\'ам'**
  String get deliveryPerChange;

  /// No description provided for @buildIosLabel.
  ///
  /// In ru, this message translates to:
  /// **'iOS {version}'**
  String buildIosLabel(String version);

  /// No description provided for @buildAndroidLabel.
  ///
  /// In ru, this message translates to:
  /// **'Android {version}'**
  String buildAndroidLabel(String version);

  /// No description provided for @sprintEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет активного спринта.\nСоздайте его командой /opsx:doc.'**
  String get sprintEmpty;

  /// No description provided for @unrecognizedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разобрано {done} из {total} — остальное приложение не поняло'**
  String unrecognizedTitle(int done, int total);

  /// No description provided for @unrecognizedNote.
  ///
  /// In ru, this message translates to:
  /// **'Спека может быть устроена не по-нашему. Экраны, которым эти данные нужны, объяснят нехватку у себя.'**
  String get unrecognizedNote;

  /// No description provided for @unrecognizedManual.
  ///
  /// In ru, this message translates to:
  /// **'Указать вручную'**
  String get unrecognizedManual;

  /// No description provided for @unrecognizedNotFound.
  ///
  /// In ru, this message translates to:
  /// **'не найдено'**
  String get unrecognizedNotFound;

  /// No description provided for @recognizedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что распознано'**
  String get recognizedTitle;

  /// No description provided for @recognizedSummary.
  ///
  /// In ru, this message translates to:
  /// **'Разобрано {done} требований из {total}'**
  String recognizedSummary(int done, int total);

  /// No description provided for @recognizedNote.
  ///
  /// In ru, this message translates to:
  /// **'Устройство спеки приложение вывело из её файлов, а не знало наперёд. Посмотрите, всё ли понято верно: на этом стоят все экраны.'**
  String get recognizedNote;

  /// No description provided for @recognizedEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get recognizedEdit;

  /// No description provided for @recognizedEditTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открыть {file} в редакторе: устройство спеки правится в ней самой'**
  String recognizedEditTooltip(String file);

  /// No description provided for @recognizedManySources.
  ///
  /// In ru, this message translates to:
  /// **'собрано из нескольких источников'**
  String get recognizedManySources;

  /// No description provided for @recognizedMatrixTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что будет работать'**
  String get recognizedMatrixTitle;

  /// No description provided for @recognizedMatrixNote.
  ///
  /// In ru, this message translates to:
  /// **'Выключенная фича не прячет экран: он останется и объяснит, чего не хватает.'**
  String get recognizedMatrixNote;

  /// No description provided for @recognizedFeatureOn.
  ///
  /// In ru, this message translates to:
  /// **'работает'**
  String get recognizedFeatureOn;

  /// No description provided for @recognizedFeatureOff.
  ///
  /// In ru, this message translates to:
  /// **'выключено'**
  String get recognizedFeatureOff;

  /// No description provided for @recognizedFeatureBlocker.
  ///
  /// In ru, this message translates to:
  /// **'не хватает: {requirement}'**
  String recognizedFeatureBlocker(String requirement);

  /// No description provided for @recognizedOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть спеку'**
  String get recognizedOpen;

  /// No description provided for @recognizedAnotherSpec.
  ///
  /// In ru, this message translates to:
  /// **'Указать другой адрес'**
  String get recognizedAnotherSpec;

  /// No description provided for @partRecognizedSchema.
  ///
  /// In ru, this message translates to:
  /// **'Схема артефактов'**
  String get partRecognizedSchema;

  /// No description provided for @partRecognizedGrouping.
  ///
  /// In ru, this message translates to:
  /// **'Группировка работы'**
  String get partRecognizedGrouping;

  /// No description provided for @partRecognizedStacks.
  ///
  /// In ru, this message translates to:
  /// **'Стеки'**
  String get partRecognizedStacks;

  /// No description provided for @partRecognizedStatuses.
  ///
  /// In ru, this message translates to:
  /// **'Статусы трекера'**
  String get partRecognizedStatuses;

  /// No description provided for @partRecognizedCommands.
  ///
  /// In ru, this message translates to:
  /// **'Команды спеки'**
  String get partRecognizedCommands;

  /// No description provided for @partRecognizedServices.
  ///
  /// In ru, this message translates to:
  /// **'Репозитории кода'**
  String get partRecognizedServices;

  /// No description provided for @partValueStatuses.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} статус} few{{count} статуса} other{{count} статусов}}'**
  String partValueStatuses(int count);

  /// No description provided for @partValueCommands.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} команда} few{{count} команды} other{{count} команд}}'**
  String partValueCommands(int count);

  /// No description provided for @partValueServices.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} репозиторий} few{{count} репозитория} other{{count} репозиториев}}'**
  String partValueServices(int count);

  /// No description provided for @partValueNoStacks.
  ///
  /// In ru, this message translates to:
  /// **'без стеков'**
  String get partValueNoStacks;

  /// No description provided for @groupingSprintDir.
  ///
  /// In ru, this message translates to:
  /// **'по спринтам'**
  String get groupingSprintDir;

  /// No description provided for @groupingMasterDoc.
  ///
  /// In ru, this message translates to:
  /// **'по мастер-спекам'**
  String get groupingMasterDoc;

  /// No description provided for @groupingNone.
  ///
  /// In ru, this message translates to:
  /// **'плоский список'**
  String get groupingNone;

  /// No description provided for @partialTrackerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статусы трекера недоступны — показаны данные файлов спеки'**
  String get partialTrackerTitle;

  /// No description provided for @partialRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get partialRetry;

  /// No description provided for @redmineUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Статусы Redmine недоступны ({reason}) — показаны данные файлов'**
  String redmineUnavailable(String reason);

  /// No description provided for @redmineNoKey.
  ///
  /// In ru, this message translates to:
  /// **'нет ключа REDMINE_API_KEY'**
  String get redmineNoKey;

  /// No description provided for @redmineDown.
  ///
  /// In ru, this message translates to:
  /// **'Redmine недоступен: {reason}'**
  String redmineDown(String reason);

  /// No description provided for @platformRepoNotFound.
  ///
  /// In ru, this message translates to:
  /// **'репозиторий платформы не найден'**
  String get platformRepoNotFound;

  /// No description provided for @divergencesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расхождения — {count}'**
  String divergencesTitle(int count);

  /// No description provided for @divergenceTasksNotClosed.
  ///
  /// In ru, this message translates to:
  /// **'статус «{status}», но не закрыты задачи {nums}'**
  String divergenceTasksNotClosed(String status, String nums);

  /// No description provided for @divergenceMarksAhead.
  ///
  /// In ru, this message translates to:
  /// **'галочки {done}/{total}, но задача в статусе «{status}»'**
  String divergenceMarksAhead(int done, int total, String status);

  /// No description provided for @divergenceBuildMissing.
  ///
  /// In ru, this message translates to:
  /// **'есть задачи в «Ожидает тестирования», но сборка {stack} не записана'**
  String divergenceBuildMissing(String stack);

  /// No description provided for @tableHeaderChange.
  ///
  /// In ru, this message translates to:
  /// **'CHANGE'**
  String get tableHeaderChange;

  /// No description provided for @tableHeaderIos.
  ///
  /// In ru, this message translates to:
  /// **'iOS'**
  String get tableHeaderIos;

  /// No description provided for @tableHeaderAndroid.
  ///
  /// In ru, this message translates to:
  /// **'ANDROID'**
  String get tableHeaderAndroid;

  /// No description provided for @stackIos.
  ///
  /// In ru, this message translates to:
  /// **'iOS'**
  String get stackIos;

  /// No description provided for @stackAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Android'**
  String get stackAndroid;

  /// No description provided for @statusUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'нет доступа'**
  String get statusUnavailable;

  /// No description provided for @marksOpenTask.
  ///
  /// In ru, this message translates to:
  /// **'открыта {num}'**
  String marksOpenTask(String num);

  /// No description provided for @marksTooltipNotClosed.
  ///
  /// In ru, this message translates to:
  /// **'не закрыто: {list}'**
  String marksTooltipNotClosed(String list);

  /// No description provided for @marksTooltipDiverged.
  ///
  /// In ru, this message translates to:
  /// **'есть расхождение'**
  String get marksTooltipDiverged;

  /// No description provided for @nextStepTitle.
  ///
  /// In ru, this message translates to:
  /// **'Следующий шаг: закрыть задачу {num} «{title}» — открыта в {count} стеках'**
  String nextStepTitle(String num, String title, int count);

  /// No description provided for @nextStepReason.
  ///
  /// In ru, this message translates to:
  /// **'иначе спринт не пройдёт проверку готовности при передаче'**
  String get nextStepReason;

  /// No description provided for @nextStepCommand.
  ///
  /// In ru, this message translates to:
  /// **'открыть tasks_*.md в change\'ах'**
  String get nextStepCommand;

  /// No description provided for @backToChanges.
  ///
  /// In ru, this message translates to:
  /// **'← Ко всем change\'ам'**
  String get backToChanges;

  /// No description provided for @backFallback.
  ///
  /// In ru, this message translates to:
  /// **'← Назад'**
  String get backFallback;

  /// No description provided for @tasksOfStack.
  ///
  /// In ru, this message translates to:
  /// **'Задачи стека {stack}'**
  String tasksOfStack(String stack);

  /// No description provided for @blocksHandover.
  ///
  /// In ru, this message translates to:
  /// **'блокирует передачу'**
  String get blocksHandover;

  /// No description provided for @artifactsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Артефакты'**
  String get artifactsTitle;

  /// No description provided for @artifactSpec.
  ///
  /// In ru, this message translates to:
  /// **'Спека'**
  String get artifactSpec;

  /// No description provided for @changeSpecTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спека изменения'**
  String get changeSpecTitle;

  /// No description provided for @changeSpecLoading.
  ///
  /// In ru, this message translates to:
  /// **'читаем спеку…'**
  String get changeSpecLoading;

  /// No description provided for @changeSpecMissing.
  ///
  /// In ru, this message translates to:
  /// **'Спека ещё не написана'**
  String get changeSpecMissing;

  /// No description provided for @changeSpecMissingHint.
  ///
  /// In ru, this message translates to:
  /// **'схема ждёт файл {file} в каталоге change\'а'**
  String changeSpecMissingHint(String file);

  /// No description provided for @changeSpecOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть целиком'**
  String get changeSpecOpen;

  /// No description provided for @changeSpecExpandHere.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть здесь'**
  String get changeSpecExpandHere;

  /// No description provided for @changeSpecCollapse.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get changeSpecCollapse;

  /// No description provided for @changeMoreActions.
  ///
  /// In ru, this message translates to:
  /// **'Ещё действия'**
  String get changeMoreActions;

  /// No description provided for @changeActionsHint.
  ///
  /// In ru, this message translates to:
  /// **'команда подставится в строку ввода сессии'**
  String get changeActionsHint;

  /// No description provided for @artifactWaits.
  ///
  /// In ru, this message translates to:
  /// **'ждёт: {what}'**
  String artifactWaits(String what);

  /// No description provided for @artifactReady.
  ///
  /// In ru, this message translates to:
  /// **'можно писать'**
  String get artifactReady;

  /// No description provided for @artifactMissing.
  ///
  /// In ru, this message translates to:
  /// **'объявлен схемой, файла нет'**
  String get artifactMissing;

  /// No description provided for @codeOffSpec.
  ///
  /// In ru, this message translates to:
  /// **'Эта спека не настроена на работу с MR'**
  String get codeOffSpec;

  /// No description provided for @codeOffPersonal.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы видеть MR, введите свой токен GitLab'**
  String get codeOffPersonal;

  /// No description provided for @codeOffRuntime.
  ///
  /// In ru, this message translates to:
  /// **'Хостинг кода не ответил или отклонил ключ'**
  String get codeOffRuntime;

  /// No description provided for @gateRuntimeRetry.
  ///
  /// In ru, this message translates to:
  /// **'Проверить снова'**
  String get gateRuntimeRetry;

  /// No description provided for @gateRuntimeChangeKey.
  ///
  /// In ru, this message translates to:
  /// **'Изменить ключ'**
  String get gateRuntimeChangeKey;

  /// No description provided for @artifactDesign.
  ///
  /// In ru, this message translates to:
  /// **'Дизайн-решения'**
  String get artifactDesign;

  /// No description provided for @artifactTasksIos.
  ///
  /// In ru, this message translates to:
  /// **'Задачи iOS'**
  String get artifactTasksIos;

  /// No description provided for @artifactTasksAndroid.
  ///
  /// In ru, this message translates to:
  /// **'Задачи Android'**
  String get artifactTasksAndroid;

  /// No description provided for @docReadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать файл:\n\n{error}'**
  String docReadError(String error);

  /// No description provided for @envTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверки окружения'**
  String get envTitle;

  /// No description provided for @envAllGood.
  ///
  /// In ru, this message translates to:
  /// **'всё готово к работе'**
  String get envAllGood;

  /// No description provided for @envProblems.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} проблема} few{{count} проблемы} other{{count} проблем}} — часть действий не сработает'**
  String envProblems(int count);

  /// No description provided for @envRecheck.
  ///
  /// In ru, this message translates to:
  /// **'Перепроверить всё'**
  String get envRecheck;

  /// No description provided for @envKeysSection.
  ///
  /// In ru, this message translates to:
  /// **'Ключи в .env — показывается только наличие, не значения'**
  String get envKeysSection;

  /// No description provided for @envReposSection.
  ///
  /// In ru, this message translates to:
  /// **'Репозитории'**
  String get envReposSection;

  /// No description provided for @envSystemsSection.
  ///
  /// In ru, this message translates to:
  /// **'Внешние системы'**
  String get envSystemsSection;

  /// No description provided for @envHintRedmineUrl.
  ///
  /// In ru, this message translates to:
  /// **'адрес Redmine'**
  String get envHintRedmineUrl;

  /// No description provided for @envHintRedmineKey.
  ///
  /// In ru, this message translates to:
  /// **'доступ к задачам'**
  String get envHintRedmineKey;

  /// No description provided for @envHintGitlabUrl.
  ///
  /// In ru, this message translates to:
  /// **'адрес GitLab'**
  String get envHintGitlabUrl;

  /// No description provided for @envHintGitlabToken.
  ///
  /// In ru, this message translates to:
  /// **'доступ к MR и веткам'**
  String get envHintGitlabToken;

  /// No description provided for @envHintMattermostUrl.
  ///
  /// In ru, this message translates to:
  /// **'адрес Mattermost'**
  String get envHintMattermostUrl;

  /// No description provided for @envHintMattermostBot.
  ///
  /// In ru, this message translates to:
  /// **'бот уведомлений'**
  String get envHintMattermostBot;

  /// No description provided for @envHintMattermostDevChannel.
  ///
  /// In ru, this message translates to:
  /// **'канал разработчиков'**
  String get envHintMattermostDevChannel;

  /// No description provided for @envHintMattermostTeamChannel.
  ///
  /// In ru, this message translates to:
  /// **'канал команды — уведомление о передаче'**
  String get envHintMattermostTeamChannel;

  /// No description provided for @envHintRole.
  ///
  /// In ru, this message translates to:
  /// **'роль машины'**
  String get envHintRole;

  /// No description provided for @checkFilled.
  ///
  /// In ru, this message translates to:
  /// **'заполнен'**
  String get checkFilled;

  /// No description provided for @checkMissing.
  ///
  /// In ru, this message translates to:
  /// **'отсутствует — добавьте в .env'**
  String get checkMissing;

  /// No description provided for @checkSynced.
  ///
  /// In ru, this message translates to:
  /// **'синхронизирован'**
  String get checkSynced;

  /// No description provided for @checkBehind.
  ///
  /// In ru, this message translates to:
  /// **'отстаёт от origin на {count}'**
  String checkBehind(int count);

  /// No description provided for @checkNotCloned.
  ///
  /// In ru, this message translates to:
  /// **'не склонирован — make init'**
  String get checkNotCloned;

  /// No description provided for @checkExpectedRef.
  ///
  /// In ru, this message translates to:
  /// **'ожидается {ref}'**
  String checkExpectedRef(String ref);

  /// No description provided for @checkResponds.
  ///
  /// In ru, this message translates to:
  /// **'отвечает · {ms} мс'**
  String checkResponds(int ms);

  /// No description provided for @checkRespondsCode.
  ///
  /// In ru, this message translates to:
  /// **'отвечает · код {code}'**
  String checkRespondsCode(int code);

  /// No description provided for @checkTimeout.
  ///
  /// In ru, this message translates to:
  /// **'таймаут 8 с'**
  String get checkTimeout;

  /// No description provided for @checkNoConnection.
  ///
  /// In ru, this message translates to:
  /// **'нет соединения'**
  String get checkNoConnection;

  /// No description provided for @checkNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'адрес не задан в .env'**
  String get checkNotConfigured;

  /// No description provided for @checkNotChecked.
  ///
  /// In ru, this message translates to:
  /// **'не проверялся'**
  String get checkNotChecked;

  /// No description provided for @handoffTitle.
  ///
  /// In ru, this message translates to:
  /// **'Передача спринта'**
  String get handoffTitle;

  /// No description provided for @handoffNote.
  ///
  /// In ru, this message translates to:
  /// **'Мастер из четырёх шагов: готовность, сборка, получатели, предпросмотр. Следующий этап реализации.'**
  String get handoffNote;

  /// No description provided for @sessionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Агентные сессии'**
  String get sessionsTitle;

  /// No description provided for @sessionsNote.
  ///
  /// In ru, this message translates to:
  /// **'Диалоги Claude Code в headless-режиме появятся после экранов состояния.'**
  String get sessionsNote;

  /// No description provided for @loaderMessage.
  ///
  /// In ru, this message translates to:
  /// **'Читаю состояние платформы…'**
  String get loaderMessage;

  /// No description provided for @setupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Какая спека?'**
  String get setupTitle;

  /// No description provided for @setupNote.
  ///
  /// In ru, this message translates to:
  /// **'Консоль читает файлы спеки — openspec-репозитория команды (workspace.yaml, openspec/, .env). Укажите путь к локальной копии: подойдёт любая спека, не только avtoto-platform.'**
  String get setupNote;

  /// No description provided for @setupFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Адрес репозитория спеки или путь к локальной копии'**
  String get setupFieldLabel;

  /// No description provided for @cloneConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get cloneConnect;

  /// No description provided for @cloneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Клонируем репозиторий'**
  String get cloneTitle;

  /// No description provided for @clonePulling.
  ///
  /// In ru, this message translates to:
  /// **'Обновляем уже склонированную спеку'**
  String get clonePulling;

  /// No description provided for @cloneTargetHint.
  ///
  /// In ru, this message translates to:
  /// **'Похоже на git-адрес — склонируем вашим git в {path}'**
  String cloneTargetHint(String path);

  /// No description provided for @cloneLocalHint.
  ///
  /// In ru, this message translates to:
  /// **'Похоже на путь — откроем локальную копию, ничего не скачиваем'**
  String get cloneLocalHint;

  /// No description provided for @cloneMeasure.
  ///
  /// In ru, this message translates to:
  /// **'{volume} · {speed}'**
  String cloneMeasure(String volume, String speed);

  /// No description provided for @cloneDone.
  ///
  /// In ru, this message translates to:
  /// **'Спека склонирована — читаем её'**
  String get cloneDone;

  /// No description provided for @cloneFailAccessDenied.
  ///
  /// In ru, this message translates to:
  /// **'Git не пустил по ssh-ключу. Проверьте, что ключ этой машины добавлен в ваш профиль на хостинге, или дайте адрес по https.'**
  String get cloneFailAccessDenied;

  /// No description provided for @cloneFailAuth.
  ///
  /// In ru, this message translates to:
  /// **'Логин или токен не приняты. Для https нужен personal access token, а не пароль от аккаунта.'**
  String get cloneFailAuth;

  /// No description provided for @cloneFailDirInUse.
  ///
  /// In ru, this message translates to:
  /// **'Каталог уже занят другим репозиторием — Spok его не тронет. Уберите каталог или подключите спеку как локальную копию.'**
  String get cloneFailDirInUse;

  /// No description provided for @cloneFailRepoNotFound.
  ///
  /// In ru, this message translates to:
  /// **'По этому адресу репозитория нет или он вам не открыт. Проверьте адрес и доступ к проекту.'**
  String get cloneFailRepoNotFound;

  /// No description provided for @cloneFailNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Хостинг не отвечает: нет сети или он недоступен с этой машины.'**
  String get cloneFailNetwork;

  /// No description provided for @cloneFailGitMissing.
  ///
  /// In ru, this message translates to:
  /// **'На машине не нашлось git — установите его и повторите.'**
  String get cloneFailGitMissing;

  /// No description provided for @cloneFailCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Клонирование отменено, недокачанный каталог убран.'**
  String get cloneFailCancelled;

  /// No description provided for @cloneFailUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Git не смог склонировать репозиторий. Его сообщение — ниже.'**
  String get cloneFailUnknown;

  /// No description provided for @setupSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get setupSave;

  /// No description provided for @setupError.
  ///
  /// In ru, this message translates to:
  /// **'По этому пути нет openspec/ или workspace.yaml — укажите корень репозитория спеки'**
  String get setupError;

  /// No description provided for @setupConfigHint.
  ///
  /// In ru, this message translates to:
  /// **'Хранится в {path} (ключ AVTOTO_PLATFORM_DIR); переменные окружения SPEC_PLATFORM_DIR и AVTOTO_PLATFORM_DIR имеют приоритет.'**
  String setupConfigHint(String path);

  /// No description provided for @stackFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все стеки'**
  String get stackFilterAll;

  /// No description provided for @openInRedmineTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открыть задачу в Redmine'**
  String get openInRedmineTooltip;

  /// No description provided for @dependenciesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Зависимости'**
  String get dependenciesTitle;

  /// No description provided for @dependsOnLabel.
  ///
  /// In ru, this message translates to:
  /// **'ЗАВИСИТ ОТ'**
  String get dependsOnLabel;

  /// No description provided for @dependentsLabel.
  ///
  /// In ru, this message translates to:
  /// **'ОТ НЕГО ЗАВИСЯТ'**
  String get dependentsLabel;

  /// No description provided for @dependenciesNone.
  ///
  /// In ru, this message translates to:
  /// **'нет зависимостей'**
  String get dependenciesNone;

  /// No description provided for @sprintBranchLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ветка спринта'**
  String get sprintBranchLabel;

  /// No description provided for @handoffStepReadiness.
  ///
  /// In ru, this message translates to:
  /// **'Готовность'**
  String get handoffStepReadiness;

  /// No description provided for @handoffStepBuild.
  ///
  /// In ru, this message translates to:
  /// **'Сборка'**
  String get handoffStepBuild;

  /// No description provided for @handoffStepRecipients.
  ///
  /// In ru, this message translates to:
  /// **'Получатели'**
  String get handoffStepRecipients;

  /// No description provided for @handoffStepPreview.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр и отправка'**
  String get handoffStepPreview;

  /// No description provided for @handoffReadyCount.
  ///
  /// In ru, this message translates to:
  /// **'{ready} из {total} change\'ей готовы к передаче'**
  String handoffReadyCount(int ready, int total);

  /// No description provided for @handoffBlockersLabel.
  ///
  /// In ru, this message translates to:
  /// **'БЛОКЕРЫ'**
  String get handoffBlockersLabel;

  /// No description provided for @handoffNoBlockers.
  ///
  /// In ru, this message translates to:
  /// **'блокеров нет — спринт можно передавать'**
  String get handoffNoBlockers;

  /// No description provided for @handoffBlockerStatus.
  ///
  /// In ru, this message translates to:
  /// **'{change} — {stack} в статусе «{status}», ожидается «Ожидает тестирования»'**
  String handoffBlockerStatus(String change, String stack, String status);

  /// No description provided for @handoffBlockerTasks.
  ///
  /// In ru, this message translates to:
  /// **'{change} — {stack}: не закрыты задачи {nums}'**
  String handoffBlockerTasks(String change, String stack, String nums);

  /// No description provided for @handoffBlockerBuild.
  ///
  /// In ru, this message translates to:
  /// **'сборка {stack} не записана в builds.yaml'**
  String handoffBlockerBuild(String stack);

  /// No description provided for @handoffBuildRecordedAt.
  ///
  /// In ru, this message translates to:
  /// **'записана {date}'**
  String handoffBuildRecordedAt(String date);

  /// No description provided for @handoffBuildMissingShort.
  ///
  /// In ru, this message translates to:
  /// **'не записана'**
  String get handoffBuildMissingShort;

  /// No description provided for @handoffRecipientsNote.
  ///
  /// In ru, this message translates to:
  /// **'Тестировщик и менеджер определяются из ролей Redmine и членства в канале Mattermost при отправке (scripts/sprint-handover-recipients.mjs).'**
  String get handoffRecipientsNote;

  /// No description provided for @handoffRecipientTester.
  ///
  /// In ru, this message translates to:
  /// **'Тестировщик'**
  String get handoffRecipientTester;

  /// No description provided for @handoffRecipientManager.
  ///
  /// In ru, this message translates to:
  /// **'Менеджер'**
  String get handoffRecipientManager;

  /// No description provided for @handoffRecipientPending.
  ///
  /// In ru, this message translates to:
  /// **'будет выбран при отправке'**
  String get handoffRecipientPending;

  /// No description provided for @handoffPreviewLabel.
  ///
  /// In ru, this message translates to:
  /// **'СООБЩЕНИЕ В КАНАЛ КОМАНДЫ'**
  String get handoffPreviewLabel;

  /// No description provided for @handoffEffectsLabel.
  ///
  /// In ru, this message translates to:
  /// **'ЧТО ПРОИЗОЙДЁТ'**
  String get handoffEffectsLabel;

  /// No description provided for @handoffEffectAssignee.
  ///
  /// In ru, this message translates to:
  /// **'в {count} задачах сменится исполнитель'**
  String handoffEffectAssignee(int count);

  /// No description provided for @handoffEffectComment.
  ///
  /// In ru, this message translates to:
  /// **'в {count} задач уйдёт комментарий со сборкой'**
  String handoffEffectComment(int count);

  /// No description provided for @handoffEffectMessage.
  ///
  /// In ru, this message translates to:
  /// **'в канал команды уйдёт 1 сообщение'**
  String get handoffEffectMessage;

  /// No description provided for @handoffSendButton.
  ///
  /// In ru, this message translates to:
  /// **'Отправить спринт тестировщику'**
  String get handoffSendButton;

  /// No description provided for @handoffSendBlocked.
  ///
  /// In ru, this message translates to:
  /// **'недоступно: готовность {ready} из {total} — устраните блокеры шага 1'**
  String handoffSendBlocked(int ready, int total);

  /// No description provided for @handoffSendNotImplemented.
  ///
  /// In ru, this message translates to:
  /// **'отправка появится в следующем этапе — через скрипты платформы'**
  String get handoffSendNotImplemented;

  /// No description provided for @handoverMsgTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спринт передан на тестирование'**
  String get handoverMsgTitle;

  /// No description provided for @handoverMsgSprint.
  ///
  /// In ru, this message translates to:
  /// **'Спринт: {title}'**
  String handoverMsgSprint(String title);

  /// No description provided for @handoverMsgStack.
  ///
  /// In ru, this message translates to:
  /// **'Стек: {stack}'**
  String handoverMsgStack(String stack);

  /// No description provided for @handoverMsgRecipients.
  ///
  /// In ru, this message translates to:
  /// **'Тестировщик: {tester} · Менеджер: {manager}'**
  String handoverMsgRecipients(String tester, String manager);

  /// No description provided for @handoverMsgBuild.
  ///
  /// In ru, this message translates to:
  /// **'Сборка: {build}'**
  String handoverMsgBuild(String build);

  /// No description provided for @handoverMsgComposition.
  ///
  /// In ru, this message translates to:
  /// **'Состав спринта'**
  String get handoverMsgComposition;

  /// No description provided for @handoverMsgOrder.
  ///
  /// In ru, this message translates to:
  /// **'Порядок проверки'**
  String get handoverMsgOrder;

  /// No description provided for @handoverMsgTaskLine.
  ///
  /// In ru, this message translates to:
  /// **'  {issue} — {title} — {status}; задачи {marks}'**
  String handoverMsgTaskLine(
    String issue,
    String title,
    String status,
    String marks,
  );

  /// No description provided for @handoverMsgOrderAfter.
  ///
  /// In ru, this message translates to:
  /// **' (после {issues})'**
  String handoverMsgOrderAfter(String issues);

  /// No description provided for @sessionsListTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сессии'**
  String get sessionsListTitle;

  /// No description provided for @sessionNew.
  ///
  /// In ru, this message translates to:
  /// **'Новая сессия'**
  String get sessionNew;

  /// No description provided for @sessionEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Опишите задачу — агент выполнит её в репозитории платформы.\nНапример: «разбери дефект из #63577» или «/opsx:sprint pin-biometric-auth status».'**
  String get sessionEmptyHint;

  /// No description provided for @sessionInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Задача для агента…'**
  String get sessionInputHint;

  /// No description provided for @sessionRunning.
  ///
  /// In ru, this message translates to:
  /// **'идёт'**
  String get sessionRunning;

  /// No description provided for @sessionWaiting.
  ///
  /// In ru, this message translates to:
  /// **'ждёт ввода'**
  String get sessionWaiting;

  /// No description provided for @sessionDone.
  ///
  /// In ru, this message translates to:
  /// **'завершена'**
  String get sessionDone;

  /// No description provided for @sessionFailed.
  ///
  /// In ru, this message translates to:
  /// **'ошибка'**
  String get sessionFailed;

  /// No description provided for @sessionStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get sessionStop;

  /// No description provided for @sessionActionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'ВЫПОЛНЕНО ПО ХОДУ'**
  String get sessionActionsLabel;

  /// No description provided for @sessionResultLabel.
  ///
  /// In ru, this message translates to:
  /// **'Итог · {duration} с'**
  String sessionResultLabel(String duration);

  /// No description provided for @sessionCliMissing.
  ///
  /// In ru, this message translates to:
  /// **'Claude Code CLI не найден. Установите его и перезапустите приложение.'**
  String get sessionCliMissing;

  /// No description provided for @sessionWorkingDir.
  ///
  /// In ru, this message translates to:
  /// **'рабочая папка: {dir}'**
  String sessionWorkingDir(String dir);

  /// No description provided for @sessionCommandsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Команды платформы'**
  String get sessionCommandsTitle;

  /// No description provided for @sessionCommandsHint.
  ///
  /// In ru, this message translates to:
  /// **'наберите / для подсказок — список и описания те же, что в терминале'**
  String get sessionCommandsHint;

  /// No description provided for @sessionNewTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Новая сессия'**
  String get sessionNewTooltip;

  /// No description provided for @sessionDeleteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сессию'**
  String get sessionDeleteTooltip;

  /// No description provided for @sessionUntitled.
  ///
  /// In ru, this message translates to:
  /// **'Пустая сессия'**
  String get sessionUntitled;

  /// No description provided for @sessionIdle.
  ///
  /// In ru, this message translates to:
  /// **'готова'**
  String get sessionIdle;

  /// No description provided for @sessionMessages.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} сообщение} few{{count} сообщения} other{{count} сообщений}}'**
  String sessionMessages(int count);

  /// No description provided for @sessionEffortLabel.
  ///
  /// In ru, this message translates to:
  /// **'усилия'**
  String get sessionEffortLabel;

  /// No description provided for @sessionContinues.
  ///
  /// In ru, this message translates to:
  /// **'диалог продолжается — агент помнит контекст'**
  String get sessionContinues;

  /// No description provided for @sessionKeyboardHint.
  ///
  /// In ru, this message translates to:
  /// **'↑↓ — выбор, Tab — вставить, Enter — отправить, Esc — скрыть'**
  String get sessionKeyboardHint;

  /// No description provided for @sessionArgumentsFor.
  ///
  /// In ru, this message translates to:
  /// **'аргументы {command}'**
  String sessionArgumentsFor(String command);

  /// No description provided for @launchPanelIdle.
  ///
  /// In ru, this message translates to:
  /// **'команды ещё не выполнялись'**
  String get launchPanelIdle;

  /// No description provided for @launchPanelRunning.
  ///
  /// In ru, this message translates to:
  /// **'выполняется…'**
  String get launchPanelRunning;

  /// No description provided for @launchPanelExit.
  ///
  /// In ru, this message translates to:
  /// **'код {code} · {seconds} с'**
  String launchPanelExit(int code, String seconds);

  /// No description provided for @launchCopyCommand.
  ///
  /// In ru, this message translates to:
  /// **'копировать команду'**
  String get launchCopyCommand;

  /// No description provided for @launchCopyOutput.
  ///
  /// In ru, this message translates to:
  /// **'копировать вывод'**
  String get launchCopyOutput;

  /// No description provided for @launchCopied.
  ///
  /// In ru, this message translates to:
  /// **'скопировано'**
  String get launchCopied;

  /// No description provided for @launchNoOutput.
  ///
  /// In ru, this message translates to:
  /// **'вывод пуст'**
  String get launchNoOutput;

  /// No description provided for @freshJustNow.
  ///
  /// In ru, this message translates to:
  /// **'обновлено только что'**
  String get freshJustNow;

  /// No description provided for @freshMinutes.
  ///
  /// In ru, this message translates to:
  /// **'обновлено {count} мин назад'**
  String freshMinutes(int count);

  /// No description provided for @freshHours.
  ///
  /// In ru, this message translates to:
  /// **'обновлено {count} ч назад'**
  String freshHours(int count);

  /// No description provided for @freshStale.
  ///
  /// In ru, this message translates to:
  /// **'данные устарели'**
  String get freshStale;

  /// No description provided for @freshRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get freshRefresh;

  /// No description provided for @codeSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Код · {stack}'**
  String codeSectionTitle(String stack);

  /// No description provided for @codeSprintBranch.
  ///
  /// In ru, this message translates to:
  /// **'ветка спринта'**
  String get codeSprintBranch;

  /// No description provided for @codeNoBranch.
  ///
  /// In ru, this message translates to:
  /// **'ветка спринта не задана в sprint.yaml'**
  String get codeNoBranch;

  /// No description provided for @commentsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Комментарии Redmine'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'комментариев нет'**
  String get commentsEmpty;

  /// No description provided for @commentsUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'комментарии недоступны без ключа Redmine'**
  String get commentsUnavailable;

  /// No description provided for @codeMrOpened.
  ///
  /// In ru, this message translates to:
  /// **'MR !{iid} — открыт'**
  String codeMrOpened(int iid);

  /// No description provided for @codeMrMerged.
  ///
  /// In ru, this message translates to:
  /// **'MR !{iid} — смержен'**
  String codeMrMerged(int iid);

  /// No description provided for @codeMrClosed.
  ///
  /// In ru, this message translates to:
  /// **'MR !{iid} — закрыт'**
  String codeMrClosed(int iid);

  /// No description provided for @codeMrNone.
  ///
  /// In ru, this message translates to:
  /// **'MR не найден'**
  String get codeMrNone;

  /// No description provided for @codeFactMerged.
  ///
  /// In ru, this message translates to:
  /// **'факт: коммит есть в {branch}'**
  String codeFactMerged(String branch);

  /// No description provided for @codeFactMissing.
  ///
  /// In ru, this message translates to:
  /// **'факт: коммита нет в {branch} — расхождение'**
  String codeFactMissing(String branch);

  /// No description provided for @codeFactUnknown.
  ///
  /// In ru, this message translates to:
  /// **'факт влития не проверен'**
  String get codeFactUnknown;

  /// No description provided for @codeGitlabUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'GitLab недоступен — нет ключа или связи'**
  String get codeGitlabUnavailable;

  /// No description provided for @codeChangeBranch.
  ///
  /// In ru, this message translates to:
  /// **'ветка change\'а'**
  String get codeChangeBranch;

  /// No description provided for @codeOpenMr.
  ///
  /// In ru, this message translates to:
  /// **'открыть MR'**
  String get codeOpenMr;

  /// No description provided for @commentsShowAll.
  ///
  /// In ru, this message translates to:
  /// **'показать все ({count})'**
  String commentsShowAll(int count);

  /// No description provided for @handoffSendConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Передача запустит команду платформы в агентной сессии — там будет виден каждый шаг. Отправить?'**
  String get handoffSendConfirm;

  /// No description provided for @handoffSendCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get handoffSendCancel;

  /// No description provided for @handoffSendRun.
  ///
  /// In ru, this message translates to:
  /// **'Запустить передачу'**
  String get handoffSendRun;

  /// No description provided for @handoffStackNotice.
  ///
  /// In ru, this message translates to:
  /// **'передаётся один стек за раз — выбран {stack}'**
  String handoffStackNotice(String stack);

  /// No description provided for @handoffPickStack.
  ///
  /// In ru, this message translates to:
  /// **'выберите стек в фильтре: передача идёт по одному стеку'**
  String get handoffPickStack;

  /// No description provided for @handoffRecipientsResolve.
  ///
  /// In ru, this message translates to:
  /// **'Подобрать получателей'**
  String get handoffRecipientsResolve;

  /// No description provided for @handoffRecipientsResolving.
  ///
  /// In ru, this message translates to:
  /// **'скрипт платформы опрашивает Redmine и Mattermost…'**
  String get handoffRecipientsResolving;

  /// No description provided for @handoffRecipientsHint.
  ///
  /// In ru, this message translates to:
  /// **'получатели ещё не подобраны — нажмите, чтобы увидеть, кому уйдёт передача'**
  String get handoffRecipientsHint;

  /// No description provided for @handoffRecipientsSource.
  ///
  /// In ru, this message translates to:
  /// **'роли Redmine × участники канала · scripts/sprint-handover-recipients.mjs'**
  String get handoffRecipientsSource;

  /// No description provided for @handoffRecipientsError.
  ///
  /// In ru, this message translates to:
  /// **'не удалось подобрать: {reason}'**
  String handoffRecipientsError(String reason);

  /// No description provided for @handoffRecipientsDevelopers.
  ///
  /// In ru, this message translates to:
  /// **'Разработчики'**
  String get handoffRecipientsDevelopers;

  /// No description provided for @handoffRecipientMain.
  ///
  /// In ru, this message translates to:
  /// **'получит задачи'**
  String get handoffRecipientMain;

  /// No description provided for @handoffRecipientAlso.
  ///
  /// In ru, this message translates to:
  /// **'ещё {count} в канале'**
  String handoffRecipientAlso(int count);

  /// No description provided for @permissionAsk.
  ///
  /// In ru, this message translates to:
  /// **'по правилам платформы'**
  String get permissionAsk;

  /// No description provided for @permissionAcceptEdits.
  ///
  /// In ru, this message translates to:
  /// **'правки без вопросов'**
  String get permissionAcceptEdits;

  /// No description provided for @permissionBypass.
  ///
  /// In ru, this message translates to:
  /// **'полный доступ'**
  String get permissionBypass;

  /// No description provided for @permissionLabel.
  ///
  /// In ru, this message translates to:
  /// **'доступ'**
  String get permissionLabel;

  /// No description provided for @permissionHint.
  ///
  /// In ru, this message translates to:
  /// **'в headless-режиме подтвердить запрос вручную нельзя: если команде нужен инструмент вне allow-списка платформы, выберите режим с автоматическим разрешением'**
  String get permissionHint;

  /// No description provided for @handoffRunsWithBypass.
  ///
  /// In ru, this message translates to:
  /// **'Сессия запустится с полным доступом к инструментам — иначе команда остановится на запросе разрешения.'**
  String get handoffRunsWithBypass;

  /// No description provided for @handoffRecipientChoose.
  ///
  /// In ru, this message translates to:
  /// **'выбрать'**
  String get handoffRecipientChoose;

  /// No description provided for @handoffRecipientChosen.
  ///
  /// In ru, this message translates to:
  /// **'получит передачу'**
  String get handoffRecipientChosen;

  /// No description provided for @sprintCreateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый спринт'**
  String get sprintCreateTitle;

  /// No description provided for @sprintCreateNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Идентификатор спринта (латиницей, через дефис)'**
  String get sprintCreateNameLabel;

  /// No description provided for @sprintCreateBriefLabel.
  ///
  /// In ru, this message translates to:
  /// **'ТЗ: вставьте текст или приложите файл'**
  String get sprintCreateBriefLabel;

  /// No description provided for @sprintCreateAttach.
  ///
  /// In ru, this message translates to:
  /// **'Приложить файл…'**
  String get sprintCreateAttach;

  /// No description provided for @sprintCreateAttached.
  ///
  /// In ru, this message translates to:
  /// **'приложен {name}'**
  String sprintCreateAttached(String name);

  /// No description provided for @sprintCreateRun.
  ///
  /// In ru, this message translates to:
  /// **'Создать спринт'**
  String get sprintCreateRun;

  /// No description provided for @sprintCreateHint.
  ///
  /// In ru, this message translates to:
  /// **'Запустится /opsx-doc — агент составит мастер-спеку и файлы спринта в openspec/doc.'**
  String get sprintCreateHint;

  /// No description provided for @sprintCreateNameError.
  ///
  /// In ru, this message translates to:
  /// **'нужен идентификатор латиницей: например profile-v2'**
  String get sprintCreateNameError;

  /// No description provided for @sprintCreateBriefError.
  ///
  /// In ru, this message translates to:
  /// **'нужен текст ТЗ или приложенный файл'**
  String get sprintCreateBriefError;

  /// No description provided for @sprintCreateTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Новый спринт из ТЗ'**
  String get sprintCreateTooltip;

  /// No description provided for @sprintNoChanges.
  ///
  /// In ru, this message translates to:
  /// **'В спринте «{title}» пока нет change\'ей'**
  String sprintNoChanges(String title);

  /// No description provided for @sprintNoChangesHint.
  ///
  /// In ru, this message translates to:
  /// **'Change — единица работы: спека, задачи, код и тест-кейсы. Создайте первый, чтобы спринт начал двигаться.'**
  String get sprintNoChangesHint;

  /// No description provided for @sprintCreateChange.
  ///
  /// In ru, this message translates to:
  /// **'Создать change'**
  String get sprintCreateChange;

  /// No description provided for @sprintOpenMasterDoc.
  ///
  /// In ru, this message translates to:
  /// **'Открыть мастер-спеку'**
  String get sprintOpenMasterDoc;

  /// No description provided for @sprintCommandPreview.
  ///
  /// In ru, this message translates to:
  /// **'Создание запустит команду спеки:'**
  String get sprintCommandPreview;

  /// No description provided for @changeCreateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый change в спринте'**
  String get changeCreateTitle;

  /// No description provided for @changeCreateNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Идентификатор change\'а (латиницей, через дефис)'**
  String get changeCreateNameLabel;

  /// No description provided for @changeCreateBriefLabel.
  ///
  /// In ru, this message translates to:
  /// **'Что нужно сделать — коротко или подробно'**
  String get changeCreateBriefLabel;

  /// No description provided for @changeCreateHint.
  ///
  /// In ru, this message translates to:
  /// **'Запустится /opsx-propose с мастер-спекой спринта — агент создаст спеку, задачи и тест-кейсы.'**
  String get changeCreateHint;

  /// No description provided for @changeCreateRun.
  ///
  /// In ru, this message translates to:
  /// **'Создать change'**
  String get changeCreateRun;

  /// No description provided for @applyRun.
  ///
  /// In ru, this message translates to:
  /// **'Реализовать {stack}'**
  String applyRun(String stack);

  /// No description provided for @applyHint.
  ///
  /// In ru, this message translates to:
  /// **'запустит /opsx-apply в агентной сессии'**
  String get applyHint;

  /// No description provided for @applyDone.
  ///
  /// In ru, this message translates to:
  /// **'все задачи закрыты'**
  String get applyDone;

  /// No description provided for @appBadgeGeneric.
  ///
  /// In ru, this message translates to:
  /// **'КОНСОЛЬ СПЕК'**
  String get appBadgeGeneric;

  /// No description provided for @navGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get navGroup;

  /// No description provided for @groupTitleSprint.
  ///
  /// In ru, this message translates to:
  /// **'Спринт: {title}'**
  String groupTitleSprint(String title);

  /// No description provided for @groupTitleMasterDoc.
  ///
  /// In ru, this message translates to:
  /// **'Мастер-спека: {title}'**
  String groupTitleMasterDoc(String title);

  /// No description provided for @groupTitleFlat.
  ///
  /// In ru, this message translates to:
  /// **'Change\'и'**
  String get groupTitleFlat;

  /// No description provided for @groupSwitcherTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Переключить группу · openspec/doc'**
  String get groupSwitcherTooltip;

  /// No description provided for @groupNone.
  ///
  /// In ru, this message translates to:
  /// **'Группировки нет — показаны все change’и'**
  String get groupNone;

  /// No description provided for @groupEmptyAll.
  ///
  /// In ru, this message translates to:
  /// **'В спеке пока нет change\'ей'**
  String get groupEmptyAll;

  /// No description provided for @stackWork.
  ///
  /// In ru, this message translates to:
  /// **'Работа'**
  String get stackWork;

  /// No description provided for @stackBackend.
  ///
  /// In ru, this message translates to:
  /// **'Backend'**
  String get stackBackend;

  /// No description provided for @stackMobile.
  ///
  /// In ru, this message translates to:
  /// **'Mobile'**
  String get stackMobile;

  /// No description provided for @stackDesign.
  ///
  /// In ru, this message translates to:
  /// **'Дизайн'**
  String get stackDesign;

  /// No description provided for @stackFilterAllShort.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get stackFilterAllShort;

  /// No description provided for @statusFromCache.
  ///
  /// In ru, this message translates to:
  /// **'из файла'**
  String get statusFromCache;

  /// No description provided for @statusFromCacheHint.
  ///
  /// In ru, this message translates to:
  /// **'Статус взят из redmine.yaml change’а — трекер не опрошен'**
  String get statusFromCacheHint;

  /// No description provided for @changeFormatWarning.
  ///
  /// In ru, this message translates to:
  /// **'Формат файла не распознан: {detail}'**
  String changeFormatWarning(String detail);

  /// No description provided for @artifactsProgress.
  ///
  /// In ru, this message translates to:
  /// **'{done} из {total} артефактов заполнены'**
  String artifactsProgress(String done, String total);

  /// No description provided for @artifactTasksOfStack.
  ///
  /// In ru, this message translates to:
  /// **'Задачи {stack}'**
  String artifactTasksOfStack(String stack);

  /// No description provided for @handoffUnavailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Передача недоступна для этой спеки'**
  String get handoffUnavailableTitle;

  /// No description provided for @handoffRequirementsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чего не хватает'**
  String get handoffRequirementsTitle;

  /// No description provided for @featureReasonNoGrouping.
  ///
  /// In ru, this message translates to:
  /// **'спека не группирует change’и: нет спринтов (openspec/doc/<id>/sprint.yaml) и мастер-спек'**
  String get featureReasonNoGrouping;

  /// No description provided for @featureReasonNoBuildsFile.
  ///
  /// In ru, this message translates to:
  /// **'спека не ведёт сборки — нет builds.yaml у группы'**
  String get featureReasonNoBuildsFile;

  /// No description provided for @featureReasonNoStatusSemantics.
  ///
  /// In ru, this message translates to:
  /// **'нет openspec/redmine.yaml — неизвестно, какой статус означает готовность'**
  String get featureReasonNoStatusSemantics;

  /// No description provided for @featureReasonNoHandoverCommand.
  ///
  /// In ru, this message translates to:
  /// **'нет команды с ролью handover'**
  String get featureReasonNoHandoverCommand;

  /// No description provided for @featureReasonNoRecipientsScript.
  ///
  /// In ru, this message translates to:
  /// **'нет скрипта подбора получателей'**
  String get featureReasonNoRecipientsScript;

  /// No description provided for @featureReasonKeyNotInExample.
  ///
  /// In ru, this message translates to:
  /// **'эта спека не настроена на работу с MR — GITLAB_TOKEN нет в .env.example'**
  String get featureReasonKeyNotInExample;

  /// No description provided for @featureReasonKeyEmpty.
  ///
  /// In ru, this message translates to:
  /// **'токен GitLab не заполнен на этой машине'**
  String get featureReasonKeyEmpty;

  /// No description provided for @featureReasonNoServices.
  ///
  /// In ru, this message translates to:
  /// **'в workspace.yaml нет сервисов'**
  String get featureReasonNoServices;

  /// No description provided for @featureReasonSingleStack.
  ///
  /// In ru, this message translates to:
  /// **'у спеки один стек'**
  String get featureReasonSingleStack;

  /// No description provided for @codeOpenInGitlab.
  ///
  /// In ru, this message translates to:
  /// **'Открыть ветку в GitLab'**
  String get codeOpenInGitlab;

  /// No description provided for @codeTargetBranch.
  ///
  /// In ru, this message translates to:
  /// **'Целевая ветка'**
  String get codeTargetBranch;

  /// No description provided for @buildsNotTracked.
  ///
  /// In ru, this message translates to:
  /// **'Спека не ведёт сборки — шаг недоступен'**
  String get buildsNotTracked;

  /// No description provided for @specSwitchTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сменить спеку — указать другой репозиторий'**
  String get specSwitchTooltip;

  /// No description provided for @setupCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get setupCancel;

  /// No description provided for @setupHintPath.
  ///
  /// In ru, this message translates to:
  /// **'/Users/…/avelacom-platform'**
  String get setupHintPath;

  /// No description provided for @setupBrowse.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать каталог…'**
  String get setupBrowse;

  /// No description provided for @setupCloneHint.
  ///
  /// In ru, this message translates to:
  /// **'Клонируем вашим git: работают ваши ssh-ключи и настройки — пароль приложение не спрашивает.'**
  String get setupCloneHint;

  /// No description provided for @groupTitleUngrouped.
  ///
  /// In ru, this message translates to:
  /// **'Вне мастер-спек'**
  String get groupTitleUngrouped;

  /// No description provided for @specSwitcherTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сменить спеку'**
  String get specSwitcherTooltip;

  /// No description provided for @specAdd.
  ///
  /// In ru, this message translates to:
  /// **'Подключить другую спеку…'**
  String get specAdd;

  /// No description provided for @envEditOpen.
  ///
  /// In ru, this message translates to:
  /// **'Заполнить ключи'**
  String get envEditOpen;

  /// No description provided for @envEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ключи спеки'**
  String get envEditTitle;

  /// No description provided for @envEditSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в .env'**
  String get envEditSave;

  /// No description provided for @envEditOptional.
  ///
  /// In ru, this message translates to:
  /// **'необязательный'**
  String get envEditOptional;

  /// No description provided for @envEditSecretNote.
  ///
  /// In ru, this message translates to:
  /// **'Секреты пишутся и в .env спеки — этот файл нужен её скриптам и агентным сессиям. Файл производный: его можно удалить, значения вернутся из хранилища.'**
  String get envEditSecretNote;

  /// No description provided for @envEditSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем ключи'**
  String get envEditSaving;

  /// No description provided for @envEditStoreKeychain.
  ///
  /// In ru, this message translates to:
  /// **'Секреты сохраняются в Keychain'**
  String get envEditStoreKeychain;

  /// No description provided for @envEditStoreLibsecret.
  ///
  /// In ru, this message translates to:
  /// **'Секреты сохраняются в связку ключей системы'**
  String get envEditStoreLibsecret;

  /// No description provided for @envEditStoreFile.
  ///
  /// In ru, this message translates to:
  /// **'Связки ключей на этой машине нет — секреты лежат в файле приложения с правами 0600'**
  String get envEditStoreFile;

  /// No description provided for @envEditGitWarning.
  ///
  /// In ru, this message translates to:
  /// **'.env не закрыт .gitignore — секреты могут уехать в репозиторий'**
  String get envEditGitWarning;

  /// No description provided for @envEditPath.
  ///
  /// In ru, this message translates to:
  /// **'Файл: {path}'**
  String envEditPath(String path);

  /// No description provided for @envEditShow.
  ///
  /// In ru, this message translates to:
  /// **'Показать значение'**
  String get envEditShow;

  /// No description provided for @envEditHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть значение'**
  String get envEditHide;

  /// No description provided for @envEditEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Пустое поле убирает ключ из файла'**
  String get envEditEmptyHint;

  /// No description provided for @featureHandoffTitle.
  ///
  /// In ru, this message translates to:
  /// **'Передача тестировщику'**
  String get featureHandoffTitle;

  /// No description provided for @featureHandoffWhy.
  ///
  /// In ru, this message translates to:
  /// **'Собирает сборку, получателей и текст сообщения, показывает предпросмотр и запускает команду сдачи спеки.'**
  String get featureHandoffWhy;

  /// No description provided for @featureBuildsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сборки'**
  String get featureBuildsTitle;

  /// No description provided for @featureBuildsWhy.
  ///
  /// In ru, this message translates to:
  /// **'Показывает последнюю сборку каждого стека и предупреждает, когда её забыли записать.'**
  String get featureBuildsWhy;

  /// No description provided for @featureMergeRequestsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Код и merge request’ы'**
  String get featureMergeRequestsTitle;

  /// No description provided for @featureMergeRequestsWhy.
  ///
  /// In ru, this message translates to:
  /// **'Показывает MR change’а рядом с фактом влития коммита в целевую ветку.'**
  String get featureMergeRequestsWhy;

  /// No description provided for @featureChatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения команде'**
  String get featureChatTitle;

  /// No description provided for @featureChatWhy.
  ///
  /// In ru, this message translates to:
  /// **'Отправляет уведомление о передаче в канал команды после предпросмотра.'**
  String get featureChatWhy;

  /// No description provided for @featureMultiStackTitle.
  ///
  /// In ru, this message translates to:
  /// **'Несколько стеков'**
  String get featureMultiStackTitle;

  /// No description provided for @featureMultiStackWhy.
  ///
  /// In ru, this message translates to:
  /// **'Разделяет задачи change’а по стекам и даёт переключатель стеков.'**
  String get featureMultiStackWhy;

  /// No description provided for @gateProgress.
  ///
  /// In ru, this message translates to:
  /// **'выполнено {done} из {total}'**
  String gateProgress(String done, String total);

  /// No description provided for @gateMandatory.
  ///
  /// In ru, this message translates to:
  /// **'ОБЯЗАТЕЛЬНОЕ'**
  String get gateMandatory;

  /// No description provided for @gateOptional.
  ///
  /// In ru, this message translates to:
  /// **'НЕОБЯЗАТЕЛЬНОЕ · БЕЗ НЕГО ШАГ ГАСНЕТ'**
  String get gateOptional;

  /// No description provided for @gateFound.
  ///
  /// In ru, this message translates to:
  /// **'найдено'**
  String get gateFound;

  /// No description provided for @gateMissing.
  ///
  /// In ru, this message translates to:
  /// **'не найдено'**
  String get gateMissing;

  /// No description provided for @reqGrouping.
  ///
  /// In ru, this message translates to:
  /// **'Группировка работы'**
  String get reqGrouping;

  /// No description provided for @reqStatusSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Семантика статусов трекера'**
  String get reqStatusSemantics;

  /// No description provided for @reqBuildsFile.
  ///
  /// In ru, this message translates to:
  /// **'Сборки'**
  String get reqBuildsFile;

  /// No description provided for @reqHandoverCommand.
  ///
  /// In ru, this message translates to:
  /// **'Команда передачи'**
  String get reqHandoverCommand;

  /// No description provided for @reqRecipientsScript.
  ///
  /// In ru, this message translates to:
  /// **'Скрипт получателей'**
  String get reqRecipientsScript;

  /// No description provided for @reqGitlabTokenDeclared.
  ///
  /// In ru, this message translates to:
  /// **'Спека работает с MR'**
  String get reqGitlabTokenDeclared;

  /// No description provided for @reqGitlabTokenFilled.
  ///
  /// In ru, this message translates to:
  /// **'Токен GitLab на этой машине'**
  String get reqGitlabTokenFilled;

  /// No description provided for @reqGitlabReachable.
  ///
  /// In ru, this message translates to:
  /// **'GitLab отвечает'**
  String get reqGitlabReachable;

  /// No description provided for @reqServices.
  ///
  /// In ru, this message translates to:
  /// **'Сервисы workspace'**
  String get reqServices;

  /// No description provided for @reqChatKeysDeclared.
  ///
  /// In ru, this message translates to:
  /// **'Спека работает с мессенджером'**
  String get reqChatKeysDeclared;

  /// No description provided for @reqChatKeysFilled.
  ///
  /// In ru, this message translates to:
  /// **'Ключи мессенджера на этой машине'**
  String get reqChatKeysFilled;

  /// No description provided for @missingKeyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ключа нет только на этой машине — спека тут не при чём'**
  String get missingKeyTitle;

  /// No description provided for @missingKeyNote.
  ///
  /// In ru, this message translates to:
  /// **'Значение уйдёт в хранилище секретов, а не в репозиторий'**
  String get missingKeyNote;

  /// No description provided for @gatePersonalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не настроено на этой машине'**
  String get gatePersonalTitle;

  /// No description provided for @gatePersonalNote.
  ///
  /// In ru, this message translates to:
  /// **'Спека это поддерживает, а у вас ключ пустой. Полминуты — и фича заработает.'**
  String get gatePersonalNote;

  /// No description provided for @gatePersonalFill.
  ///
  /// In ru, this message translates to:
  /// **'Заполнить'**
  String get gatePersonalFill;

  /// No description provided for @gateRuntimeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настроено, но система не отвечает'**
  String get gateRuntimeTitle;

  /// No description provided for @gateRuntimeEditKey.
  ///
  /// In ru, this message translates to:
  /// **'Изменить ключ'**
  String get gateRuntimeEditKey;

  /// No description provided for @gateCopyTemplate.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать шаблон'**
  String get gateCopyTemplate;

  /// No description provided for @gateAskAgent.
  ///
  /// In ru, this message translates to:
  /// **'Создать через агента'**
  String get gateAskAgent;

  /// No description provided for @gateTemplateCopied.
  ///
  /// In ru, this message translates to:
  /// **'Шаблон скопирован в буфер'**
  String get gateTemplateCopied;

  /// No description provided for @reqStacks.
  ///
  /// In ru, this message translates to:
  /// **'Два стека и больше'**
  String get reqStacks;

  /// No description provided for @sessionQuickLaunch.
  ///
  /// In ru, this message translates to:
  /// **'БЫСТРЫЙ ЗАПУСК'**
  String get sessionQuickLaunch;

  /// No description provided for @sessionMoreActions.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get sessionMoreActions;

  /// No description provided for @sessionAllCommands.
  ///
  /// In ru, this message translates to:
  /// **'Все команды спеки'**
  String get sessionAllCommands;

  /// No description provided for @sessionModelLabel.
  ///
  /// In ru, this message translates to:
  /// **'модель'**
  String get sessionModelLabel;

  /// No description provided for @sessionRunHint.
  ///
  /// In ru, this message translates to:
  /// **'⏎ запустить'**
  String get sessionRunHint;

  /// No description provided for @sessionParamsShort.
  ///
  /// In ru, this message translates to:
  /// **'⋯ параметры'**
  String get sessionParamsShort;

  /// No description provided for @sessionInputEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'выберите команду или опишите задачу'**
  String get sessionInputEmptyHint;

  /// No description provided for @sessionInputCommandHint.
  ///
  /// In ru, this message translates to:
  /// **'добавьте словами, что сделать'**
  String get sessionInputCommandHint;

  /// No description provided for @sessionPaletteTitle.
  ///
  /// In ru, this message translates to:
  /// **'КОМАНДЫ СПЕКИ'**
  String get sessionPaletteTitle;

  /// No description provided for @sessionPaletteFooter.
  ///
  /// In ru, this message translates to:
  /// **'↑↓ выбрать · Tab вставить в строку · Esc закрыть'**
  String get sessionPaletteFooter;

  /// No description provided for @sessionPaletteFilter.
  ///
  /// In ru, this message translates to:
  /// **'фильтр {filter} · {shown} из {total}'**
  String sessionPaletteFilter(String filter, int shown, int total);

  /// No description provided for @sessionPaletteAll.
  ///
  /// In ru, this message translates to:
  /// **'{total} команд · зеркала скрыты'**
  String sessionPaletteAll(int total);

  /// No description provided for @sessionNoArguments.
  ///
  /// In ru, this message translates to:
  /// **'аргументы не описаны'**
  String get sessionNoArguments;

  /// No description provided for @sessionNextSteps.
  ///
  /// In ru, this message translates to:
  /// **'СЛЕДУЮЩИЕ ШАГИ'**
  String get sessionNextSteps;

  /// No description provided for @sessionNextStepCommand.
  ///
  /// In ru, this message translates to:
  /// **'команда {command} спеки'**
  String sessionNextStepCommand(String command);

  /// No description provided for @sessionNextStepOpenChange.
  ///
  /// In ru, this message translates to:
  /// **'Открыть change'**
  String get sessionNextStepOpenChange;

  /// No description provided for @sessionNextStepOpenChangeHint.
  ///
  /// In ru, this message translates to:
  /// **'посмотреть, что осталось'**
  String get sessionNextStepOpenChangeHint;

  /// No description provided for @sessionTerminalHeightTooltip.
  ///
  /// In ru, this message translates to:
  /// **'высота терминала — тяните границу'**
  String get sessionTerminalHeightTooltip;

  /// No description provided for @sessionCustomModel.
  ///
  /// In ru, this message translates to:
  /// **'Указать модель…'**
  String get sessionCustomModel;

  /// No description provided for @sessionCustomModelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Модель для сессии'**
  String get sessionCustomModelTitle;

  /// No description provided for @sessionCustomModelHint.
  ///
  /// In ru, this message translates to:
  /// **'имя модели или псевдоним — уйдёт в --model как есть'**
  String get sessionCustomModelHint;

  /// No description provided for @sessionDoneChecklist.
  ///
  /// In ru, this message translates to:
  /// **'ВЫПОЛНЕНО ПО ХОДУ'**
  String get sessionDoneChecklist;

  /// No description provided for @commandSourceSchema.
  ///
  /// In ru, this message translates to:
  /// **'канон схемы'**
  String get commandSourceSchema;

  /// No description provided for @commandSourceClaude.
  ///
  /// In ru, this message translates to:
  /// **'.claude'**
  String get commandSourceClaude;

  /// No description provided for @commandSourceMirror.
  ///
  /// In ru, this message translates to:
  /// **'зеркало'**
  String get commandSourceMirror;

  /// No description provided for @commandSourcePackage.
  ///
  /// In ru, this message translates to:
  /// **'package.json'**
  String get commandSourcePackage;

  /// No description provided for @commandSourceMake.
  ///
  /// In ru, this message translates to:
  /// **'Makefile'**
  String get commandSourceMake;

  /// No description provided for @roleApply.
  ///
  /// In ru, this message translates to:
  /// **'Реализовать'**
  String get roleApply;

  /// No description provided for @roleNewChange.
  ///
  /// In ru, this message translates to:
  /// **'Новый change'**
  String get roleNewChange;

  /// No description provided for @roleNewGroup.
  ///
  /// In ru, this message translates to:
  /// **'Новая группа'**
  String get roleNewGroup;

  /// No description provided for @roleHandover.
  ///
  /// In ru, this message translates to:
  /// **'Передача'**
  String get roleHandover;

  /// No description provided for @navDocs.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get navDocs;

  /// No description provided for @docsTitle.
  ///
  /// In ru, this message translates to:
  /// **'ДОКУМЕНТЫ СПЕКИ'**
  String get docsTitle;

  /// No description provided for @docsTreeCount.
  ///
  /// In ru, this message translates to:
  /// **'{present} из {declared}'**
  String docsTreeCount(int present, int declared);

  /// No description provided for @docsArchiveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get docsArchiveTitle;

  /// No description provided for @docsArchivedAt.
  ///
  /// In ru, this message translates to:
  /// **'в архиве с {date}'**
  String docsArchivedAt(String date);

  /// No description provided for @docsArchivedNoDate.
  ///
  /// In ru, this message translates to:
  /// **'в архиве, дата не указана'**
  String get docsArchivedNoDate;

  /// No description provided for @docsUngrouped.
  ///
  /// In ru, this message translates to:
  /// **'Вне групп'**
  String get docsUngrouped;

  /// No description provided for @docsMasterDoc.
  ///
  /// In ru, this message translates to:
  /// **'Мастер-спека'**
  String get docsMasterDoc;

  /// No description provided for @docsGroupDoc.
  ///
  /// In ru, this message translates to:
  /// **'Документ группы'**
  String get docsGroupDoc;

  /// No description provided for @docsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В спеке нет ни одного документа'**
  String get docsEmpty;

  /// No description provided for @docsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Документы появляются вместе с change\'ами: спека изменения, дизайн-решения и задачи лежат в его каталоге.'**
  String get docsEmptyHint;

  /// No description provided for @docsNothingOpened.
  ///
  /// In ru, this message translates to:
  /// **'Выберите документ слева'**
  String get docsNothingOpened;

  /// No description provided for @docsNothingOpenedHint.
  ///
  /// In ru, this message translates to:
  /// **'Дерево повторяет устройство спеки: группа, её change\'и и файлы артефактов схемы.'**
  String get docsNothingOpenedHint;

  /// No description provided for @docsMissingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Файла нет'**
  String get docsMissingTitle;

  /// No description provided for @docsMissingHint.
  ///
  /// In ru, this message translates to:
  /// **'Артефакт {file} объявлен схемой, но ещё не написан.'**
  String docsMissingHint(String file);

  /// No description provided for @docsLoading.
  ///
  /// In ru, this message translates to:
  /// **'Читаем файл…'**
  String get docsLoading;

  /// No description provided for @docsOpenInIde.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в IDE'**
  String get docsOpenInIde;

  /// No description provided for @docsOpenInIdeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не нашли, чем открыть файл: установите редактор или откройте его вручную'**
  String get docsOpenInIdeFailed;

  /// No description provided for @docsBranchClean.
  ///
  /// In ru, this message translates to:
  /// **'в ветке {branch}'**
  String docsBranchClean(String branch);

  /// No description provided for @docsBranchModified.
  ///
  /// In ru, this message translates to:
  /// **'изменён локально · {branch}'**
  String docsBranchModified(String branch);

  /// No description provided for @docsBranchUntracked.
  ///
  /// In ru, this message translates to:
  /// **'ещё не в git · {branch}'**
  String docsBranchUntracked(String branch);

  /// No description provided for @docsBranchUnknown.
  ///
  /// In ru, this message translates to:
  /// **'git не ответил о состоянии файла'**
  String get docsBranchUnknown;

  /// No description provided for @docsOpenChange.
  ///
  /// In ru, this message translates to:
  /// **'Открыть change'**
  String get docsOpenChange;

  /// No description provided for @progressCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get progressCancel;

  /// No description provided for @progressRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get progressRetry;

  /// No description provided for @progressPercent.
  ///
  /// In ru, this message translates to:
  /// **'{percent} %'**
  String progressPercent(int percent);

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get confirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
