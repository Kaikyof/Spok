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
}
