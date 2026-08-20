import '../../domain/entities/divergence.dart';
import '../../domain/entities/env_check.dart';
import '../../l10n/gen/app_localizations.dart';

/// Форматирование структурных сущностей домена в локализованный текст.
extension DomainTextFormatters on AppLocalizations {
  String stackLabel(String stack) =>
      stack == 'ios' ? stackIos : stackAndroid;

  String divergenceText(Divergence divergence) => switch (divergence.kind) {
        DivergenceKind.tasksNotClosed => divergenceTasksNotClosed(
            divergence.redmineStatus ?? '',
            divergence.openTaskNumbers.join(', ')),
        DivergenceKind.marksAheadOfStatus => divergenceMarksAhead(
            divergence.doneCount,
            divergence.totalCount,
            divergence.redmineStatus ?? ''),
        DivergenceKind.buildMissing =>
          divergenceBuildMissing(stackLabel(divergence.stack)),
      };

  String checkResultText(EnvCheck check) => switch (check.outcome) {
        CheckOutcome.keyFilled => checkFilled,
        CheckOutcome.keyMissing => checkMissing,
        CheckOutcome.roleValue => check.param,
        CheckOutcome.repoSynced => checkSynced,
        CheckOutcome.repoBehind => checkBehind(check.count),
        CheckOutcome.repoNotCloned => checkNotCloned,
        CheckOutcome.systemResponds => checkResponds(check.count),
        CheckOutcome.systemRespondsWithCode => checkRespondsCode(check.count),
        CheckOutcome.systemTimeout => checkTimeout,
        CheckOutcome.systemNoConnection => checkNoConnection,
        CheckOutcome.systemNotConfigured => checkNotConfigured,
      };

  /// Пояснение к ключу .env; для репозиториев и систем detail — данные
  /// (ветка, хост), они приходят из check.subtitle.
  String envKeyHint(String keyName) => switch (keyName) {
        'REDMINE_URL' => envHintRedmineUrl,
        'REDMINE_API_KEY' => envHintRedmineKey,
        'GITLAB_URL' => envHintGitlabUrl,
        'GITLAB_TOKEN' => envHintGitlabToken,
        'MATTERMOST_URL' => envHintMattermostUrl,
        'MATTERMOST_BOT_TOKEN' => envHintMattermostBot,
        'MATTERMOST_DEVELOPERS_CHANNEL_ID' => envHintMattermostDevChannel,
        'MATTERMOST_TEAM_CHANNEL_ID' => envHintMattermostTeamChannel,
        'AVTOTO_ROLE' => envHintRole,
        _ => '',
      };

  String roleLabel(String role) => switch (role) {
        'ios' => roleIos,
        'android' => roleAndroid,
        'qa' => roleQa,
        'dev' => roleDev,
        _ => role,
      };
}
