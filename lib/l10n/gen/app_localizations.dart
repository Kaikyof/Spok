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
  /// **'Где репозиторий платформы?'**
  String get setupTitle;

  /// No description provided for @setupNote.
  ///
  /// In ru, this message translates to:
  /// **'Консоль читает файлы avtoto-platform (workspace.yaml, .env, openspec). Укажите путь к локальной копии репозитория — он сохранится в конфиге приложения.'**
  String get setupNote;

  /// No description provided for @setupFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Путь к avtoto-platform'**
  String get setupFieldLabel;

  /// No description provided for @setupSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get setupSave;

  /// No description provided for @setupError.
  ///
  /// In ru, this message translates to:
  /// **'По этому пути нет workspace.yaml — проверьте, что это корень avtoto-platform'**
  String get setupError;

  /// No description provided for @setupConfigHint.
  ///
  /// In ru, this message translates to:
  /// **'Хранится в {path} (ключ AVTOTO_PLATFORM_DIR); переменная окружения с тем же именем имеет приоритет.'**
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
