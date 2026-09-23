import '../../domain/entities/divergence.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/doc_state.dart';
import '../../domain/entities/env_check.dart';
import '../../domain/entities/feature_gate.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/entities/stack_state.dart';
import '../../l10n/gen/app_localizations.dart';

/// Форматирование структурных сущностей домена в локализованный текст.
extension DomainTextFormatters on AppLocalizations {
  /// Имя стека: известные — человеческим названием, остальные — как их
  /// назвала спека (стеки приходят из схемы, список открытый).
  String stackLabel(String stack) => switch (stack) {
        'ios' => stackIos,
        'android' => stackAndroid,
        'backend' => stackBackend,
        'mobile' => stackMobile,
        'design' => stackDesign,
        StackState.singleWorkStack => stackWork,
        _ => stack.isEmpty
            ? stackWork
            : stack[0].toUpperCase() + stack.substring(1),
      };

  /// Заголовок группы — по стратегии группировки, а не «Спринт» всегда.
  /// [amongNamed] — у спеки есть именованные группы, и эта собрала остаток:
  /// «Change'и» тогда звучали бы так, будто других change'ей нет.
  String groupTitle(Group? group, {bool amongNamed = false}) =>
      switch (group?.kind) {
        null => groupNone,
        GroupingKind.sprintDir => groupTitleSprint(group!.title),
        GroupingKind.masterDoc => groupTitleMasterDoc(group!.title),
        GroupingKind.none =>
          amongNamed ? groupTitleUngrouped : groupTitleFlat,
      };

  /// Подпись документа: известные артефакты схемы — человеческим названием,
  /// остальные — описанием из схемы или именем файла. Список артефактов
  /// открытый: спека вправе объявить свои.
  String docLabel(DocArtifact doc) => switch (doc.id) {
        DocArtifact.masterDocId => docsMasterDoc,
        DocArtifact.groupDocId => docsGroupDoc,
        'proposal' => artifactSpec,
        'design' => artifactDesign,
        final id when id.startsWith('tasks-') =>
          artifactTasksOfStack(stackLabel(id.substring(6))),
        _ => doc.label.isEmpty ? doc.fileName : doc.label,
      };

  /// Состояние файла документа в ветке спеки.
  String docStateLabel(DocState state) => switch (state.file) {
        DocFileState.clean => docsBranchClean(state.branch),
        DocFileState.modified => docsBranchModified(state.branch),
        DocFileState.untracked => docsBranchUntracked(state.branch),
        DocFileState.unknown => docsBranchUnknown,
      };

  /// Название фичи и одно предложение «зачем она».
  String featureTitle(SpecFeature feature) => switch (feature) {
        SpecFeature.handoff => featureHandoffTitle,
        SpecFeature.builds => featureBuildsTitle,
        SpecFeature.mergeRequests => featureMergeRequestsTitle,
        SpecFeature.chat => featureChatTitle,
        SpecFeature.multiStack => featureMultiStackTitle,
      };

  String featureWhy(SpecFeature feature) => switch (feature) {
        SpecFeature.handoff => featureHandoffWhy,
        SpecFeature.builds => featureBuildsWhy,
        SpecFeature.mergeRequests => featureMergeRequestsWhy,
        SpecFeature.chat => featureChatWhy,
        SpecFeature.multiStack => featureMultiStackWhy,
      };

  /// Что именно ищет приложение — человеческим языком.
  String requirementTitle(RequirementId id) => switch (id) {
        RequirementId.grouping => reqGrouping,
        RequirementId.statusSemantics => reqStatusSemantics,
        RequirementId.buildsFile => reqBuildsFile,
        RequirementId.handoverCommand => reqHandoverCommand,
        RequirementId.recipientsScript => reqRecipientsScript,
        RequirementId.gitlabTokenDeclared => reqGitlabTokenDeclared,
        RequirementId.gitlabTokenFilled => reqGitlabTokenFilled,
        RequirementId.gitlabReachable => reqGitlabReachable,
        RequirementId.services => reqServices,
        RequirementId.chatKeysDeclared => reqChatKeysDeclared,
        RequirementId.chatKeysFilled => reqChatKeysFilled,
        RequirementId.stacks => reqStacks,
      };

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
        _ when keyName.endsWith('_ROLE') => envHintRole,
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
