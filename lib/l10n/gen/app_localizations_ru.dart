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
  String get setupTitle => 'Где репозиторий платформы?';

  @override
  String get setupNote =>
      'Консоль читает файлы avtoto-platform (workspace.yaml, .env, openspec). Укажите путь к локальной копии репозитория — он сохранится в конфиге приложения.';

  @override
  String get setupFieldLabel => 'Путь к avtoto-platform';

  @override
  String get setupSave => 'Сохранить и продолжить';

  @override
  String get setupError =>
      'По этому пути нет workspace.yaml — проверьте, что это корень avtoto-platform';

  @override
  String setupConfigHint(String path) {
    return 'Хранится в $path (ключ AVTOTO_PLATFORM_DIR); переменная окружения с тем же именем имеет приоритет.';
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
}
