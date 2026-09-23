// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appBadge => 'AVTOTO · КОНСОЛЬ';

  @override
  String get navSprint => 'Спринт';

  @override
  String get navChanges => 'Change\'и';

  @override
  String get navHandoff => 'Передача';

  @override
  String get navEnv => 'Окружение';

  @override
  String get navSessions => 'Сессии';

  @override
  String get machineRoleLabel => 'РОЛЬ МАШИНЫ';

  @override
  String get machineRoleEnvVar => 'AVTOTO_ROLE';

  @override
  String get roleNotSet => 'роль не задана';

  @override
  String get roleIos => 'iOS-разработчик';

  @override
  String get roleAndroid => 'Android-разработчик';

  @override
  String get roleQa => 'Тестировщик';

  @override
  String get roleDev => 'Разработчик (оба стека)';

  @override
  String get refreshTooltip => 'Обновить (⌘R)';

  @override
  String updatedAt(String time) {
    return 'обновлено $time';
  }

  @override
  String get sprintNone => 'Нет активного спринта';

  @override
  String sprintTitlePrefix(String title) {
    return 'Спринт: $title';
  }

  @override
  String get sprintSwitcherTooltip => 'Переключить спринт · openspec/doc';

  @override
  String get deliveryBatch => 'сдача целиком (batch)';

  @override
  String get deliveryPerChange => 'сдача по change\'ам';

  @override
  String buildIosLabel(String version) {
    return 'iOS $version';
  }

  @override
  String buildAndroidLabel(String version) {
    return 'Android $version';
  }

  @override
  String get sprintEmpty =>
      'Нет активного спринта.\nСоздайте его командой /opsx:doc.';

  @override
  String redmineUnavailable(String reason) {
    return 'Статусы Redmine недоступны ($reason) — показаны данные файлов';
  }

  @override
  String get redmineNoKey => 'нет ключа REDMINE_API_KEY';

  @override
  String redmineDown(String reason) {
    return 'Redmine недоступен: $reason';
  }

  @override
  String get platformRepoNotFound => 'репозиторий платформы не найден';

  @override
  String divergencesTitle(int count) {
    return 'Расхождения — $count';
  }

  @override
  String divergenceTasksNotClosed(String status, String nums) {
    return 'статус «$status», но не закрыты задачи $nums';
  }

  @override
  String divergenceMarksAhead(int done, int total, String status) {
    return 'галочки $done/$total, но задача в статусе «$status»';
  }

  @override
  String divergenceBuildMissing(String stack) {
    return 'есть задачи в «Ожидает тестирования», но сборка $stack не записана';
  }

  @override
  String get tableHeaderChange => 'CHANGE';

  @override
  String get tableHeaderIos => 'iOS';

  @override
  String get tableHeaderAndroid => 'ANDROID';

  @override
  String get stackIos => 'iOS';

  @override
  String get stackAndroid => 'Android';

  @override
  String get statusUnavailable => 'нет доступа';

  @override
  String marksOpenTask(String num) {
    return 'открыта $num';
  }

  @override
  String marksTooltipNotClosed(String list) {
    return 'не закрыто: $list';
  }

  @override
  String get marksTooltipDiverged => 'есть расхождение';

  @override
  String nextStepTitle(String num, String title, int count) {
    return 'Следующий шаг: закрыть задачу $num «$title» — открыта в $count стеках';
  }

  @override
  String get nextStepReason =>
      'иначе спринт не пройдёт проверку готовности при передаче';

  @override
  String get nextStepCommand => 'открыть tasks_*.md в change\'ах';

  @override
  String get backToChanges => '← Ко всем change\'ам';

  @override
  String get backFallback => '← Назад';

  @override
  String tasksOfStack(String stack) {
    return 'Задачи стека $stack';
  }

  @override
  String get blocksHandover => 'блокирует передачу';

  @override
  String get artifactsTitle => 'Артефакты';

  @override
  String get artifactSpec => 'Спека';

  @override
  String get changeSpecTitle => 'Спека изменения';

  @override
  String get changeSpecLoading => 'читаем спеку…';

  @override
  String get changeSpecMissing => 'Спека ещё не написана';

  @override
  String changeSpecMissingHint(String file) {
    return 'схема ждёт файл $file в каталоге change\'а';
  }

  @override
  String get changeSpecOpen => 'Открыть целиком';

  @override
  String get changeMoreActions => 'Ещё действия';

  @override
  String get changeActionsHint => 'команда подставится в строку ввода сессии';

  @override
  String artifactWaits(String what) {
    return 'ждёт: $what';
  }

  @override
  String get artifactReady => 'можно писать';

  @override
  String get artifactMissing => 'объявлен схемой, файла нет';

  @override
  String get codeOffSpec => 'Эта спека не настроена на работу с MR';

  @override
  String get codeOffPersonal => 'Чтобы видеть MR, введите свой токен GitLab';

  @override
  String get codeOffRuntime => 'Хостинг кода не ответил или отклонил ключ';

  @override
  String get gateRuntimeRetry => 'Проверить снова';

  @override
  String get gateRuntimeChangeKey => 'Изменить ключ';

  @override
  String get artifactDesign => 'Дизайн-решения';

  @override
  String get artifactTasksIos => 'Задачи iOS';

  @override
  String get artifactTasksAndroid => 'Задачи Android';

  @override
  String docReadError(String error) {
    return 'Не удалось прочитать файл:\n\n$error';
  }

  @override
  String get envTitle => 'Проверки окружения';

  @override
  String get envAllGood => 'всё готово к работе';

  @override
  String envProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проблем',
      few: '$count проблемы',
      one: '$count проблема',
    );
    return '$_temp0 — часть действий не сработает';
  }

  @override
  String get envRecheck => 'Перепроверить всё';

  @override
  String get envKeysSection =>
      'Ключи в .env — показывается только наличие, не значения';

  @override
  String get envReposSection => 'Репозитории';

  @override
  String get envSystemsSection => 'Внешние системы';

  @override
  String get envHintRedmineUrl => 'адрес Redmine';

  @override
  String get envHintRedmineKey => 'доступ к задачам';

  @override
  String get envHintGitlabUrl => 'адрес GitLab';

  @override
  String get envHintGitlabToken => 'доступ к MR и веткам';

  @override
  String get envHintMattermostUrl => 'адрес Mattermost';

  @override
  String get envHintMattermostBot => 'бот уведомлений';

  @override
  String get envHintMattermostDevChannel => 'канал разработчиков';

  @override
  String get envHintMattermostTeamChannel =>
      'канал команды — уведомление о передаче';

  @override
  String get envHintRole => 'роль машины';

  @override
  String get checkFilled => 'заполнен';

  @override
  String get checkMissing => 'отсутствует — добавьте в .env';

  @override
  String get checkSynced => 'синхронизирован';

  @override
  String checkBehind(int count) {
    return 'отстаёт от origin на $count';
  }

  @override
  String get checkNotCloned => 'не склонирован — make init';

  @override
  String checkExpectedRef(String ref) {
    return 'ожидается $ref';
  }

  @override
  String checkResponds(int ms) {
    return 'отвечает · $ms мс';
  }

  @override
  String checkRespondsCode(int code) {
    return 'отвечает · код $code';
  }

  @override
  String get checkTimeout => 'таймаут 8 с';

  @override
  String get checkNoConnection => 'нет соединения';

  @override
  String get checkNotConfigured => 'адрес не задан в .env';

  @override
  String get checkNotChecked => 'не проверялся';

  @override
  String get handoffTitle => 'Передача спринта';

  @override
  String get handoffNote =>
      'Мастер из четырёх шагов: готовность, сборка, получатели, предпросмотр. Следующий этап реализации.';

  @override
  String get sessionsTitle => 'Агентные сессии';

  @override
  String get sessionsNote =>
      'Диалоги Claude Code в headless-режиме появятся после экранов состояния.';

  @override
  String get loaderMessage => 'Читаю состояние платформы…';

  @override
  String get setupTitle => 'Какая спека?';

  @override
  String get setupNote =>
      'Консоль читает файлы спеки — openspec-репозитория команды (workspace.yaml, openspec/, .env). Укажите путь к локальной копии: подойдёт любая спека, не только avtoto-platform.';

  @override
  String get setupFieldLabel => 'Путь к репозиторию спеки';

  @override
  String get setupSave => 'Сохранить и продолжить';

  @override
  String get setupError =>
      'По этому пути нет openspec/ или workspace.yaml — укажите корень репозитория спеки';

  @override
  String setupConfigHint(String path) {
    return 'Хранится в $path (ключ AVTOTO_PLATFORM_DIR); переменные окружения SPEC_PLATFORM_DIR и AVTOTO_PLATFORM_DIR имеют приоритет.';
  }

  @override
  String get stackFilterAll => 'Все стеки';

  @override
  String get openInRedmineTooltip => 'Открыть задачу в Redmine';

  @override
  String get dependenciesTitle => 'Зависимости';

  @override
  String get dependsOnLabel => 'ЗАВИСИТ ОТ';

  @override
  String get dependentsLabel => 'ОТ НЕГО ЗАВИСЯТ';

  @override
  String get dependenciesNone => 'нет зависимостей';

  @override
  String get sprintBranchLabel => 'Ветка спринта';

  @override
  String get handoffStepReadiness => 'Готовность';

  @override
  String get handoffStepBuild => 'Сборка';

  @override
  String get handoffStepRecipients => 'Получатели';

  @override
  String get handoffStepPreview => 'Предпросмотр и отправка';

  @override
  String handoffReadyCount(int ready, int total) {
    return '$ready из $total change\'ей готовы к передаче';
  }

  @override
  String get handoffBlockersLabel => 'БЛОКЕРЫ';

  @override
  String get handoffNoBlockers => 'блокеров нет — спринт можно передавать';

  @override
  String handoffBlockerStatus(String change, String stack, String status) {
    return '$change — $stack в статусе «$status», ожидается «Ожидает тестирования»';
  }

  @override
  String handoffBlockerTasks(String change, String stack, String nums) {
    return '$change — $stack: не закрыты задачи $nums';
  }

  @override
  String handoffBlockerBuild(String stack) {
    return 'сборка $stack не записана в builds.yaml';
  }

  @override
  String handoffBuildRecordedAt(String date) {
    return 'записана $date';
  }

  @override
  String get handoffBuildMissingShort => 'не записана';

  @override
  String get handoffRecipientsNote =>
      'Тестировщик и менеджер определяются из ролей Redmine и членства в канале Mattermost при отправке (scripts/sprint-handover-recipients.mjs).';

  @override
  String get handoffRecipientTester => 'Тестировщик';

  @override
  String get handoffRecipientManager => 'Менеджер';

  @override
  String get handoffRecipientPending => 'будет выбран при отправке';

  @override
  String get handoffPreviewLabel => 'СООБЩЕНИЕ В КАНАЛ КОМАНДЫ';

  @override
  String get handoffEffectsLabel => 'ЧТО ПРОИЗОЙДЁТ';

  @override
  String handoffEffectAssignee(int count) {
    return 'в $count задачах сменится исполнитель';
  }

  @override
  String handoffEffectComment(int count) {
    return 'в $count задач уйдёт комментарий со сборкой';
  }

  @override
  String get handoffEffectMessage => 'в канал команды уйдёт 1 сообщение';

  @override
  String get handoffSendButton => 'Отправить спринт тестировщику';

  @override
  String handoffSendBlocked(int ready, int total) {
    return 'недоступно: готовность $ready из $total — устраните блокеры шага 1';
  }

  @override
  String get handoffSendNotImplemented =>
      'отправка появится в следующем этапе — через скрипты платформы';

  @override
  String get handoverMsgTitle => 'Спринт передан на тестирование';

  @override
  String handoverMsgSprint(String title) {
    return 'Спринт: $title';
  }

  @override
  String handoverMsgStack(String stack) {
    return 'Стек: $stack';
  }

  @override
  String handoverMsgRecipients(String tester, String manager) {
    return 'Тестировщик: $tester · Менеджер: $manager';
  }

  @override
  String handoverMsgBuild(String build) {
    return 'Сборка: $build';
  }

  @override
  String get handoverMsgComposition => 'Состав спринта';

  @override
  String get handoverMsgOrder => 'Порядок проверки';

  @override
  String handoverMsgTaskLine(
    String issue,
    String title,
    String status,
    String marks,
  ) {
    return '  $issue — $title — $status; задачи $marks';
  }

  @override
  String handoverMsgOrderAfter(String issues) {
    return ' (после $issues)';
  }

  @override
  String get sessionsListTitle => 'Сессии';

  @override
  String get sessionNew => 'Новая сессия';

  @override
  String get sessionEmptyHint =>
      'Опишите задачу — агент выполнит её в репозитории платформы.\nНапример: «разбери дефект из #63577» или «/opsx:sprint pin-biometric-auth status».';

  @override
  String get sessionInputHint => 'Задача для агента…';

  @override
  String get sessionRunning => 'идёт';

  @override
  String get sessionWaiting => 'ждёт ввода';

  @override
  String get sessionDone => 'завершена';

  @override
  String get sessionFailed => 'ошибка';

  @override
  String get sessionStop => 'Остановить';

  @override
  String get sessionActionsLabel => 'ВЫПОЛНЕНО ПО ХОДУ';

  @override
  String sessionResultLabel(String duration) {
    return 'Итог · $duration с';
  }

  @override
  String get sessionCliMissing =>
      'Claude Code CLI не найден. Установите его и перезапустите приложение.';

  @override
  String sessionWorkingDir(String dir) {
    return 'рабочая папка: $dir';
  }

  @override
  String get sessionCommandsTitle => 'Команды платформы';

  @override
  String get sessionCommandsHint =>
      'наберите / для подсказок — список и описания те же, что в терминале';

  @override
  String get sessionNewTooltip => 'Новая сессия';

  @override
  String get sessionDeleteTooltip => 'Удалить сессию';

  @override
  String get sessionUntitled => 'Пустая сессия';

  @override
  String get sessionIdle => 'готова';

  @override
  String sessionMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщений',
      few: '$count сообщения',
      one: '$count сообщение',
    );
    return '$_temp0';
  }

  @override
  String get sessionEffortLabel => 'усилия';

  @override
  String get sessionContinues => 'диалог продолжается — агент помнит контекст';

  @override
  String get sessionKeyboardHint =>
      '↑↓ — выбор, Tab — вставить, Enter — отправить, Esc — скрыть';

  @override
  String sessionArgumentsFor(String command) {
    return 'аргументы $command';
  }

  @override
  String get launchPanelIdle => 'команды ещё не выполнялись';

  @override
  String get launchPanelRunning => 'выполняется…';

  @override
  String launchPanelExit(int code, String seconds) {
    return 'код $code · $seconds с';
  }

  @override
  String get launchCopyCommand => 'копировать команду';

  @override
  String get launchCopyOutput => 'копировать вывод';

  @override
  String get launchCopied => 'скопировано';

  @override
  String get launchNoOutput => 'вывод пуст';

  @override
  String get freshJustNow => 'обновлено только что';

  @override
  String freshMinutes(int count) {
    return 'обновлено $count мин назад';
  }

  @override
  String freshHours(int count) {
    return 'обновлено $count ч назад';
  }

  @override
  String get freshStale => 'данные устарели — обновите';

  @override
  String codeSectionTitle(String stack) {
    return 'Код · $stack';
  }

  @override
  String get codeSprintBranch => 'ветка спринта';

  @override
  String get codeNoBranch => 'ветка спринта не задана в sprint.yaml';

  @override
  String get commentsTitle => 'Комментарии Redmine';

  @override
  String get commentsEmpty => 'комментариев нет';

  @override
  String get commentsUnavailable => 'комментарии недоступны без ключа Redmine';

  @override
  String codeMrOpened(int iid) {
    return 'MR !$iid — открыт';
  }

  @override
  String codeMrMerged(int iid) {
    return 'MR !$iid — смержен';
  }

  @override
  String codeMrClosed(int iid) {
    return 'MR !$iid — закрыт';
  }

  @override
  String get codeMrNone => 'MR не найден';

  @override
  String codeFactMerged(String branch) {
    return 'факт: коммит есть в $branch';
  }

  @override
  String codeFactMissing(String branch) {
    return 'факт: коммита нет в $branch — расхождение';
  }

  @override
  String get codeFactUnknown => 'факт влития не проверен';

  @override
  String get codeGitlabUnavailable => 'GitLab недоступен — нет ключа или связи';

  @override
  String get codeChangeBranch => 'ветка change\'а';

  @override
  String get codeOpenMr => 'открыть MR';

  @override
  String commentsShowAll(int count) {
    return 'показать все ($count)';
  }

  @override
  String get handoffSendConfirm =>
      'Передача запустит команду платформы в агентной сессии — там будет виден каждый шаг. Отправить?';

  @override
  String get handoffSendCancel => 'Отмена';

  @override
  String get handoffSendRun => 'Запустить передачу';

  @override
  String handoffStackNotice(String stack) {
    return 'передаётся один стек за раз — выбран $stack';
  }

  @override
  String get handoffPickStack =>
      'выберите стек в фильтре: передача идёт по одному стеку';

  @override
  String get handoffRecipientsResolve => 'Подобрать получателей';

  @override
  String get handoffRecipientsResolving =>
      'скрипт платформы опрашивает Redmine и Mattermost…';

  @override
  String get handoffRecipientsHint =>
      'получатели ещё не подобраны — нажмите, чтобы увидеть, кому уйдёт передача';

  @override
  String get handoffRecipientsSource =>
      'роли Redmine × участники канала · scripts/sprint-handover-recipients.mjs';

  @override
  String handoffRecipientsError(String reason) {
    return 'не удалось подобрать: $reason';
  }

  @override
  String get handoffRecipientsDevelopers => 'Разработчики';

  @override
  String get handoffRecipientMain => 'получит задачи';

  @override
  String handoffRecipientAlso(int count) {
    return 'ещё $count в канале';
  }

  @override
  String get permissionAsk => 'по правилам платформы';

  @override
  String get permissionAcceptEdits => 'правки без вопросов';

  @override
  String get permissionBypass => 'полный доступ';

  @override
  String get permissionLabel => 'доступ';

  @override
  String get permissionHint =>
      'в headless-режиме подтвердить запрос вручную нельзя: если команде нужен инструмент вне allow-списка платформы, выберите режим с автоматическим разрешением';

  @override
  String get handoffRunsWithBypass =>
      'Сессия запустится с полным доступом к инструментам — иначе команда остановится на запросе разрешения.';

  @override
  String get handoffRecipientChoose => 'выбрать';

  @override
  String get handoffRecipientChosen => 'получит передачу';

  @override
  String get sprintCreateTitle => 'Новый спринт';

  @override
  String get sprintCreateNameLabel =>
      'Идентификатор спринта (латиницей, через дефис)';

  @override
  String get sprintCreateBriefLabel => 'ТЗ: вставьте текст или приложите файл';

  @override
  String get sprintCreateAttach => 'Приложить файл…';

  @override
  String sprintCreateAttached(String name) {
    return 'приложен $name';
  }

  @override
  String get sprintCreateRun => 'Создать спринт';

  @override
  String get sprintCreateHint =>
      'Запустится /opsx-doc — агент составит мастер-спеку и файлы спринта в openspec/doc.';

  @override
  String get sprintCreateNameError =>
      'нужен идентификатор латиницей: например profile-v2';

  @override
  String get sprintCreateBriefError => 'нужен текст ТЗ или приложенный файл';

  @override
  String get sprintCreateTooltip => 'Новый спринт из ТЗ';

  @override
  String sprintNoChanges(String title) {
    return 'В спринте «$title» пока нет change\'ей';
  }

  @override
  String get sprintNoChangesHint =>
      'Change — единица работы: спека, задачи, код и тест-кейсы. Создайте первый, чтобы спринт начал двигаться.';

  @override
  String get sprintCreateChange => 'Создать change';

  @override
  String get changeCreateTitle => 'Новый change в спринте';

  @override
  String get changeCreateNameLabel =>
      'Идентификатор change\'а (латиницей, через дефис)';

  @override
  String get changeCreateBriefLabel =>
      'Что нужно сделать — коротко или подробно';

  @override
  String get changeCreateHint =>
      'Запустится /opsx-propose с мастер-спекой спринта — агент создаст спеку, задачи и тест-кейсы.';

  @override
  String get changeCreateRun => 'Создать change';

  @override
  String applyRun(String stack) {
    return 'Реализовать $stack';
  }

  @override
  String get applyHint => 'запустит /opsx-apply в агентной сессии';

  @override
  String get applyDone => 'все задачи закрыты';

  @override
  String get appBadgeGeneric => 'КОНСОЛЬ СПЕК';

  @override
  String get navGroup => 'Группа';

  @override
  String groupTitleSprint(String title) {
    return 'Спринт: $title';
  }

  @override
  String groupTitleMasterDoc(String title) {
    return 'Мастер-спека: $title';
  }

  @override
  String get groupTitleFlat => 'Change\'и';

  @override
  String get groupSwitcherTooltip => 'Переключить группу · openspec/doc';

  @override
  String get groupNone => 'Группировки нет — показаны все change’и';

  @override
  String get groupEmptyAll =>
      'В спеке нет change\'ей.\nСоздайте первый командой /opsx:propose.';

  @override
  String get stackWork => 'Работа';

  @override
  String get stackBackend => 'Backend';

  @override
  String get stackMobile => 'Mobile';

  @override
  String get stackDesign => 'Дизайн';

  @override
  String get stackFilterAllShort => 'Все';

  @override
  String get statusFromCache => 'из файла';

  @override
  String get statusFromCacheHint =>
      'Статус взят из redmine.yaml change’а — трекер не опрошен';

  @override
  String changeFormatWarning(String detail) {
    return 'Формат файла не распознан: $detail';
  }

  @override
  String artifactsProgress(String done, String total) {
    return '$done из $total артефактов заполнены';
  }

  @override
  String artifactTasksOfStack(String stack) {
    return 'Задачи $stack';
  }

  @override
  String get handoffUnavailableTitle => 'Передача недоступна для этой спеки';

  @override
  String get handoffRequirementsTitle => 'Чего не хватает';

  @override
  String get featureReasonNoGrouping =>
      'спека не группирует change’и: нет спринтов (openspec/doc/<id>/sprint.yaml) и мастер-спек';

  @override
  String get featureReasonNoBuildsFile =>
      'спека не ведёт сборки — нет builds.yaml у группы';

  @override
  String get featureReasonNoStatusSemantics =>
      'нет openspec/redmine.yaml — неизвестно, какой статус означает готовность';

  @override
  String get featureReasonNoHandoverCommand => 'нет команды с ролью handover';

  @override
  String get featureReasonNoRecipientsScript =>
      'нет скрипта подбора получателей';

  @override
  String get featureReasonKeyNotInExample =>
      'эта спека не настроена на работу с MR — GITLAB_TOKEN нет в .env.example';

  @override
  String get featureReasonKeyEmpty => 'токен GitLab не заполнен на этой машине';

  @override
  String get featureReasonNoServices => 'в workspace.yaml нет сервисов';

  @override
  String get featureReasonSingleStack => 'у спеки один стек';

  @override
  String get codeOpenInGitlab => 'Открыть ветку в GitLab';

  @override
  String get codeTargetBranch => 'Целевая ветка';

  @override
  String get buildsNotTracked => 'Спека не ведёт сборки — шаг недоступен';

  @override
  String get specSwitchTooltip => 'Сменить спеку — указать другой репозиторий';

  @override
  String get setupCancel => 'Отмена';

  @override
  String get setupHintPath => '/Users/…/avelacom-platform';

  @override
  String get setupBrowse => 'Выбрать каталог…';

  @override
  String get setupCloneHint =>
      'Спека ещё не склонирована? Сначала склонируйте репозиторий: git clone <url>';

  @override
  String get groupTitleUngrouped => 'Вне мастер-спек';

  @override
  String get specSwitcherTooltip => 'Сменить спеку';

  @override
  String get specAdd => 'Подключить другую спеку…';

  @override
  String get envEditOpen => 'Заполнить ключи';

  @override
  String get envEditTitle => 'Ключи спеки';

  @override
  String get envEditSave => 'Сохранить в .env';

  @override
  String get envEditOptional => 'необязательный';

  @override
  String get envEditSecretNote =>
      'Секреты пишутся в .env спеки — этот файл нужен её скриптам и агентным сессиям. Системного хранилища (Keychain) пока нет.';

  @override
  String get envEditGitWarning =>
      '.env не закрыт .gitignore — секреты могут уехать в репозиторий';

  @override
  String envEditPath(String path) {
    return 'Файл: $path';
  }

  @override
  String get envEditShow => 'Показать значение';

  @override
  String get envEditHide => 'Скрыть значение';

  @override
  String get envEditEmptyHint => 'Пустое поле убирает ключ из файла';

  @override
  String get featureHandoffTitle => 'Передача тестировщику';

  @override
  String get featureHandoffWhy =>
      'Собирает сборку, получателей и текст сообщения, показывает предпросмотр и запускает команду сдачи спеки.';

  @override
  String get featureBuildsTitle => 'Сборки';

  @override
  String get featureBuildsWhy =>
      'Показывает последнюю сборку каждого стека и предупреждает, когда её забыли записать.';

  @override
  String get featureMergeRequestsTitle => 'Код и merge request’ы';

  @override
  String get featureMergeRequestsWhy =>
      'Показывает MR change’а рядом с фактом влития коммита в целевую ветку.';

  @override
  String get featureChatTitle => 'Сообщения команде';

  @override
  String get featureChatWhy =>
      'Отправляет уведомление о передаче в канал команды после предпросмотра.';

  @override
  String get featureMultiStackTitle => 'Несколько стеков';

  @override
  String get featureMultiStackWhy =>
      'Разделяет задачи change’а по стекам и даёт переключатель стеков.';

  @override
  String gateProgress(String done, String total) {
    return 'выполнено $done из $total';
  }

  @override
  String get gateMandatory => 'ОБЯЗАТЕЛЬНОЕ';

  @override
  String get gateOptional => 'НЕОБЯЗАТЕЛЬНОЕ · БЕЗ НЕГО ШАГ ГАСНЕТ';

  @override
  String get gateFound => 'найдено';

  @override
  String get gateMissing => 'не найдено';

  @override
  String get reqGrouping => 'Группировка работы';

  @override
  String get reqStatusSemantics => 'Семантика статусов трекера';

  @override
  String get reqBuildsFile => 'Сборки';

  @override
  String get reqHandoverCommand => 'Команда передачи';

  @override
  String get reqRecipientsScript => 'Скрипт получателей';

  @override
  String get reqGitlabTokenDeclared => 'Спека работает с MR';

  @override
  String get reqGitlabTokenFilled => 'Токен GitLab на этой машине';

  @override
  String get reqGitlabReachable => 'GitLab отвечает';

  @override
  String get reqServices => 'Сервисы workspace';

  @override
  String get reqChatKeysDeclared => 'Спека работает с мессенджером';

  @override
  String get reqChatKeysFilled => 'Ключи мессенджера на этой машине';

  @override
  String get gatePersonalTitle => 'Не настроено на этой машине';

  @override
  String get gatePersonalNote =>
      'Спека это поддерживает, а у вас ключ пустой. Полминуты — и фича заработает.';

  @override
  String get gatePersonalFill => 'Заполнить';

  @override
  String get gateRuntimeTitle => 'Настроено, но система не отвечает';

  @override
  String get gateRuntimeEditKey => 'Изменить ключ';

  @override
  String get gateCopyTemplate => 'Скопировать шаблон';

  @override
  String get gateAskAgent => 'Создать через агента';

  @override
  String get gateTemplateCopied => 'Шаблон скопирован в буфер';

  @override
  String get reqStacks => 'Два стека и больше';

  @override
  String get sessionQuickLaunch => 'БЫСТРЫЙ ЗАПУСК';

  @override
  String get sessionMoreActions => 'Ещё';

  @override
  String get sessionAllCommands => 'Все команды спеки';

  @override
  String get sessionModelLabel => 'модель';

  @override
  String get sessionRunHint => '⏎ запустить';

  @override
  String get sessionParamsShort => '⋯ параметры';

  @override
  String get sessionInputEmptyHint => 'выберите команду или опишите задачу';

  @override
  String get sessionInputCommandHint => 'добавьте словами, что сделать';

  @override
  String get sessionPaletteTitle => 'КОМАНДЫ СПЕКИ';

  @override
  String get sessionPaletteFooter =>
      '↑↓ выбрать · Tab вставить в строку · Esc закрыть';

  @override
  String sessionPaletteFilter(String filter, int shown, int total) {
    return 'фильтр $filter · $shown из $total';
  }

  @override
  String sessionPaletteAll(int total) {
    return '$total команд · зеркала скрыты';
  }

  @override
  String get sessionNoArguments => 'аргументы не описаны';

  @override
  String get sessionNextSteps => 'СЛЕДУЮЩИЕ ШАГИ';

  @override
  String sessionNextStepCommand(String command) {
    return 'команда $command спеки';
  }

  @override
  String get sessionNextStepOpenChange => 'Открыть change';

  @override
  String get sessionNextStepOpenChangeHint => 'посмотреть, что осталось';

  @override
  String get sessionTerminalHeightTooltip =>
      'высота терминала — тяните границу';

  @override
  String get sessionCustomModel => 'Указать модель…';

  @override
  String get sessionCustomModelTitle => 'Модель для сессии';

  @override
  String get sessionCustomModelHint =>
      'имя модели или псевдоним — уйдёт в --model как есть';

  @override
  String get sessionDoneChecklist => 'ВЫПОЛНЕНО ПО ХОДУ';

  @override
  String get commandSourceSchema => 'канон схемы';

  @override
  String get commandSourceClaude => '.claude';

  @override
  String get commandSourceMirror => 'зеркало';

  @override
  String get commandSourcePackage => 'package.json';

  @override
  String get commandSourceMake => 'Makefile';

  @override
  String get roleApply => 'Реализовать';

  @override
  String get roleNewChange => 'Новый change';

  @override
  String get roleNewGroup => 'Новая группа';

  @override
  String get roleHandover => 'Передача';

  @override
  String get navDocs => 'Документы';

  @override
  String get docsTitle => 'ДОКУМЕНТЫ СПЕКИ';

  @override
  String docsTreeCount(int present, int declared) {
    return '$present из $declared';
  }

  @override
  String get docsArchiveTitle => 'Архив';

  @override
  String docsArchivedAt(String date) {
    return 'в архиве с $date';
  }

  @override
  String get docsArchivedNoDate => 'в архиве, дата не указана';

  @override
  String get docsUngrouped => 'Вне групп';

  @override
  String get docsMasterDoc => 'Мастер-спека';

  @override
  String get docsGroupDoc => 'Документ группы';

  @override
  String get docsEmpty => 'В спеке нет ни одного документа';

  @override
  String get docsEmptyHint =>
      'Документы появляются вместе с change\'ами: спека изменения, дизайн-решения и задачи лежат в его каталоге.';

  @override
  String get docsNothingOpened => 'Выберите документ слева';

  @override
  String get docsNothingOpenedHint =>
      'Дерево повторяет устройство спеки: группа, её change\'и и файлы артефактов схемы.';

  @override
  String get docsMissingTitle => 'Файла нет';

  @override
  String docsMissingHint(String file) {
    return 'Артефакт $file объявлен схемой, но ещё не написан.';
  }

  @override
  String get docsLoading => 'Читаем файл…';

  @override
  String get docsOpenInIde => 'Открыть в IDE';

  @override
  String get docsOpenInIdeFailed =>
      'Не нашли, чем открыть файл: установите редактор или откройте его вручную';

  @override
  String docsBranchClean(String branch) {
    return 'в ветке $branch';
  }

  @override
  String docsBranchModified(String branch) {
    return 'изменён локально · $branch';
  }

  @override
  String docsBranchUntracked(String branch) {
    return 'ещё не в git · $branch';
  }

  @override
  String get docsBranchUnknown => 'git не ответил о состоянии файла';

  @override
  String get docsOpenChange => 'Открыть change';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Готово';
}
