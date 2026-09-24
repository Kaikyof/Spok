import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/change_unit.dart';
import '../../domain/entities/clone_progress.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/project_profile.dart';
import '../../domain/entities/status_semantics.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/doc_state.dart';
import '../../domain/entities/env_check.dart';
import '../../domain/entities/env_field.dart';
import '../../domain/entities/feature_gate.dart';
import '../../domain/entities/env_report.dart';
import '../../domain/entities/handoff_recipient.dart';
import '../../domain/entities/issue_comment.dart';
import '../../domain/entities/merge_request_info.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/entities/spec_recognition.dart';
import '../../domain/entities/spec_schema.dart';
import '../../domain/repositories/command_log.dart';
import '../../domain/usecases/find_divergences.dart';
import '../../domain/usecases/find_env_commands.dart';
import '../../domain/repositories/platform_repository.dart';
import '../../domain/entities/secret_backend.dart';
import '../sources/app_config_source.dart';
import '../sources/env_materializer.dart';
import '../sources/git_clone_source.dart';
import '../sources/gitlab_api.dart';
import '../sources/ide_launcher.dart';
import '../sources/handover_recipients_source.dart';
import '../sources/platform_files_source.dart';
import '../sources/redmine_api.dart';
import '../sources/secret_store.dart';
import '../sources/env_file.dart';

class PlatformRepositoryImpl implements PlatformRepository {
  PlatformFilesSource? files;
  final AppConfigSource config;
  final CommandLog? commandLog;
  final FindDivergences findDivergences;
  final SecretStore secrets;
  final GitCloneSource cloneSource;

  /// Спеки, `.env` которых уже собран в этом запуске: пересобирать файл
  /// на каждом обновлении слепка незачем — он меняется только когда
  /// человек правит ключи.
  final _materialized = <String>{};

  PlatformRepositoryImpl(this.files,
      {AppConfigSource? config,
      this.commandLog,
      FindDivergences? findDivergences,
      SecretStore? secrets,
      GitCloneSource? cloneSource})
      : config = config ?? AppConfigSource(),
        findDivergences = findDivergences ?? FindDivergences(),
        secrets = secrets ?? SecretStore(),
        cloneSource = cloneSource ?? GitCloneSource();

  /// Сборщик `.env` текущей спеки; null — спека не подключена.
  EnvMaterializer? get _materializer {
    final source = files;
    return source == null ? null : EnvMaterializer(source, secrets: secrets);
  }

  /// Собирает `.env` спеки из хранилища секретов — один раз на спеку.
  /// Клон мог быть создан только что: без этого шага скрипты спеки
  /// стартовали бы без ключей, которые человек уже вводил.
  Future<void> materializeEnv({bool force = false}) async {
    final source = files;
    if (source == null) return;
    if (!force && !_materialized.add(source.path)) return;
    try {
      await _materializer?.materialize();
    } catch (_) {
      // Не вышло — ключи всё равно читаются из файла, как раньше.
      // Ронять загрузку спеки из-за хранилища секретов нельзя.
    }
  }

  /// Ищет платформу с учётом пути, сохранённого в конфиге приложения.
  static Future<PlatformRepositoryImpl> create({CommandLog? commandLog}) async {
    final config = AppConfigSource();
    final configuredPath = await config.readPlatformDir();
    final source = PlatformFilesSource.locate(
        configuredPath: configuredPath, commandLog: commandLog);
    // Спека, с которой приложение стартовало, тоже подключена — иначе
    // после перехода на другую вернуться к ней было бы не через что.
    if (source != null) await config.rememberSpec(source.path);
    return PlatformRepositoryImpl(
      source,
      config: config,
      commandLog: commandLog,
    );
  }

  @override
  String? get rootPath => files?.path;

  @override
  String get role => files?.role ?? '';

  @override
  String get roleKey => files?.roleKey ?? '';

  @override
  List<SlashCommand> slashCommands() => files?.loadSlashCommands() ?? const [];

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() {
    final source = files;
    if (source == null) {
      return (changeIds: const <String>[], groupIds: const <String>[]);
    }
    final changes = source.loadChanges();
    return (
      changeIds: changes.map((change) => change.id).toList(),
      groupIds: source
          .loadGroups(changes)
          .where((group) => group.id.isNotEmpty)
          .map((group) => group.id)
          .toList(),
    );
  }

  @override
  Future<String> configFilePath() => config.configPath();

  @override
  Future<bool> setPlatformDir(String path) async {
    final trimmedPath = path.trim();
    if (!PlatformFilesSource.isPlatformRoot(trimmedPath)) return false;
    await config.writePlatformDir(trimmedPath);
    await config.rememberSpec(trimmedPath);
    files = PlatformFilesSource(Directory(trimmedPath), commandLog: commandLog);
    await materializeEnv();
    return true;
  }

  @override
  Stream<CloneProgress> cloneSpec(String url, {String ref = ''}) =>
      cloneSource.clone(url, ref: ref);

  @override
  void cancelClone() => cloneSource.cancel();

  @override
  Future<List<String>> knownSpecs() async {
    final known = await config.readKnownSpecs();
    final current = rootPath;
    // Текущая спека могла попасть сюда из переменной окружения — она тоже
    // подключена, даже если в реестре её ещё нет.
    return [
      ...known,
      if (current != null && !known.contains(current)) current,
    ];
  }

  @override
  Future<EnvForm> envForm() async {
    final source = files;
    if (source == null) return EnvForm.empty;
    // Собираем файл до чтения формы: значение из связки ключей должно
    // попасть в поле, даже если в клоне его ещё нет.
    await materializeEnv();
    final env = source.loadEnv();
    return EnvForm(
      fields: [
        for (final example in source.loadEnvExampleKeys())
          EnvField(
            key: example.key,
            value: env[example.key] ?? '',
            hint: example.hint,
            optional: example.optional,
          ),
      ],
      ignoredByGit: await source.envIgnoredByGit(),
      path: source.envPath,
      backend: await secrets.backend(),
    );
  }

  @override
  Future<void> saveEnv(Map<String, String> values) async {
    final materializer = _materializer;
    if (materializer == null) return;
    await materializer.save(values);
  }

  @override
  Future<Map<String, String>> readEnvFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return const {};
    return EnvFile.parse(await file.readAsString());
  }

  @override
  Future<SecretBackend> secretBackend() => secrets.backend();

  @override
  Future<List<IssueComment>> issueComments(List<int> issueIds) async {
    final source = files;
    if (source == null || issueIds.isEmpty) return const [];
    final env = source.loadEnv();
    final baseUrl = env['REDMINE_URL'] ?? '';
    final apiKey = env['REDMINE_API_KEY'] ?? '';
    if (baseUrl.isEmpty || apiKey.isEmpty) return const [];
    final api = RedmineApi(baseUrl, apiKey);
    try {
      final perIssue = await Future.wait(issueIds.map((issueId) async {
        final comments = await api.issueComments(issueId);
        return [
          for (final comment in comments)
            IssueComment(
              issueId: issueId,
              author: comment.author,
              createdAt: comment.createdAt,
              text: comment.text,
            ),
        ];
      }));
      final all = perIssue.expand((comments) => comments).toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<HandoffRecipients> handoffRecipients(String stack) async {
    final source = files;
    if (source == null) {
      return const HandoffRecipients(error: 'platform-not-found');
    }
    return HandoverRecipientsSource(source.root,
            scriptPath: source.recipientsScript, commandLog: commandLog)
        .forStack(stack);
  }

  @override
  Future<List<MergeRequestInfo>> mergeRequests(String changeId,
      {String groupId = ''}) async {
    final source = files;
    if (source == null) return const [];
    final env = source.loadEnv();
    final baseUrl = env['GITLAB_URL'] ?? '';
    final token = env['GITLAB_TOKEN'] ?? '';
    if (baseUrl.isEmpty || token.isEmpty) return const [];

    final services = source.allServices().where((s) => s.repo.isNotEmpty);
    // Роли стеков есть — смотрим репозиторий стека; нет — все сервисы спеки.
    final stackServices = services.where((s) => s.stack.isNotEmpty);
    final targets = stackServices.isEmpty ? services : stackServices;
    if (targets.isEmpty) return const [];

    final group = source
        .loadGroups(source.loadChanges())
        .where((candidate) => candidate.id == groupId)
        .firstOrNull;
    final sourceBranch = source.loadSchema().branchFor(changeId);
    final api = GitLabApi(baseUrl, token);
    final results = await Future.wait(targets.map((service) async {
      final projectPath = GitLabApi.projectPathFromRepo(service.repo);
      if (projectPath == null) return null;
      // Цель MR — ветка группы, если спека её ведёт; иначе рабочая
      // ветка сервиса из workspace.yaml.
      final targetBranch = group?.branchFor(service.stack) ?? service.ref;
      if (targetBranch.isEmpty) return null;
      try {
        return await api.mergeRequestFor(
          projectPath: projectPath,
          stack: service.stack.isEmpty ? service.name : service.stack,
          sourceBranch: sourceBranch,
          targetBranch: targetBranch,
        );
      } on DioException {
        return null;
      }
    }));
    return results.nonNulls.toList();
  }

  @override
  Future<String> readDoc(String absolutePath) async {
    final root = rootPath;
    if (root == null || !absolutePath.startsWith(root)) {
      throw StateError('Документ вне репозитория платформы');
    }
    return File(absolutePath).readAsString();
  }

  @override
  Future<DocState> docState(String absolutePath) async =>
      await files?.docState(absolutePath) ?? DocState.unknown;

  @override
  Future<bool> openInEditor(String absolutePath) =>
      IdeLauncher(commandLog: commandLog).open(absolutePath);

  @override
  Future<ConsoleSnapshot> load() async {
    final source = files;
    if (source == null) {
      return ConsoleSnapshot(
        groups: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        redmineProblem: RedmineProblem.platformNotFound,
        refreshedAt: DateTime.now(),
      );
    }

    // Ключи возвращаем в клон до чтения: проверки окружения и трекер
    // ниже уже рассчитывают на заполненный `.env`.
    await materializeEnv();
    await source.pullPlatform();
    final changes = source.loadChanges();
    final groups = source.loadGroups(changes);
    final archived = source.loadArchivedChanges();
    final semantics = source.loadStatusSemantics();
    final (redmineProblem, redmineDetail) =
        await _fetchStatuses(source, changes);

    final env = await _buildEnvReport(source);
    return ConsoleSnapshot(
      groups: groups,
      changes: changes,
      divergences: findDivergences(groups.firstOrNull, changes, semantics),
      env: env,
      docs: source.loadDocTree(groups, changes, archived: archived),
      profile: _buildProfile(source, groups, changes, semantics, env),
      redmineProblem: redmineProblem,
      redmineProblemDetail: redmineDetail,
      redmineBaseUrl: source.loadEnv()['REDMINE_URL'] ?? '',
      refreshedAt: DateTime.now(),
    );
  }

  /// Что спека умеет: фичи включаются по факту наличия данных, а не по
  /// предположению, что у всех есть спринты, сборки и мессенджер.
  ProjectProfile _buildProfile(
    PlatformFilesSource source,
    List<Group> groups,
    List<ChangeUnit> changes,
    StatusSemantics semantics,
    EnvReport envReport,
  ) {
    final schema = source.loadSchema();
    final exampleKeys = {
      for (final example in source.loadEnvExampleKeys()) example.key
    };
    final grouping = groups
            .where((group) => group.kind != GroupingKind.none)
            .map((group) => group.kind)
            .firstOrNull ??
        GroupingKind.none;
    // Стеки — те, по которым реально есть задачи; порядок задаёт схема.
    final present = {
      for (final change in changes)
        for (final stack in change.stacks) stack.stack,
    };
    final ordered = [
      for (final stack in schema.stacks)
        if (present.contains(stack)) stack,
      for (final stack in present)
        if (!schema.stacks.contains(stack)) stack,
    ];

    return ProjectProfile(
      schema: schema,
      statuses: semantics,
      grouping: grouping,
      stacks: ordered,
      services: [
        for (final service in source.allServices())
          (
            name: service.name,
            stack: service.stack,
            webUrl: _webUrlOfRepo(service.repo),
          ),
      ],
      features: _buildGates(
        source: source,
        groups: groups,
        semantics: semantics,
        stacks: ordered,
        exampleKeys: exampleKeys,
        envValues: envReport,
      ),
      handoverCommand: _handoverCommand(source),
      envCommands: const FindEnvCommands()(source.loadSlashCommands()),
      recognition: _buildRecognition(
        source: source,
        schema: schema,
        grouping: grouping,
        stacks: ordered,
        semantics: semantics,
      ),
    );
  }

  /// Команда передачи — любая команда спеки, знающая слово handover:
  /// в avtoto это `/opsx-sprint … handover`, у другой спеки будет своё имя.
  SlashCommand? _handoverCommand(PlatformFilesSource source) =>
      source
          .loadSlashCommands()
          .where((command) =>
              command.id.contains('handover') ||
              command.argumentHint.contains('handover'))
          .firstOrNull;

  /// Что приложение поняло в спеке. Список честный: «не распознано» —
  /// такой же результат разбора, как и распознанное, и человек должен
  /// видеть его до того, как решит, что приложение сломано (борд 19).
  SpecRecognition _buildRecognition({
    required PlatformFilesSource source,
    required SpecSchema schema,
    required GroupingKind grouping,
    required List<String> stacks,
    required StatusSemantics semantics,
  }) {
    final commands = source.loadSlashCommands();
    final services = source.allServices();
    final schemaFile = source.schemaFile;
    return SpecRecognition([
      RecognizedItem(
        part: RecognizedPart.schema,
        recognized: !schema.isEmpty,
        value: schema.name,
        lookedIn: 'openspec/schemas/*/schema.yaml',
        sourcePath: schemaFile,
      ),
      // Плоский список — тоже разобранная стратегия: у спеки может не быть
      // ни спринтов, ни мастер-спек, и это не «не понято».
      RecognizedItem(
        part: RecognizedPart.grouping,
        recognized: true,
        value: grouping.name,
        lookedIn: 'openspec/doc',
        sourcePath: source.docDir,
      ),
      RecognizedItem(
        part: RecognizedPart.stacks,
        recognized: true,
        value: stacks.join(' · '),
        lookedIn: 'schema.yaml → tasks-<stack>',
        sourcePath: schemaFile,
      ),
      RecognizedItem(
        part: RecognizedPart.statuses,
        recognized: !semantics.isEmpty,
        value: '${semantics.statuses.length}',
        lookedIn: 'openspec/redmine.yaml',
        sourcePath: source.trackerFile,
      ),
      RecognizedItem(
        part: RecognizedPart.commands,
        recognized: commands.isNotEmpty,
        value: '${commands.length}',
        lookedIn: 'schema · .claude · package.json · Makefile',
      ),
      RecognizedItem(
        part: RecognizedPart.services,
        recognized: services.isNotEmpty,
        value: '${services.length}',
        lookedIn: 'workspace.yaml → services',
        sourcePath: source.workspaceFile,
      ),
    ]);
  }

  /// Требования фич — то же, что приложение ищет в спеке, но в явном виде:
  /// экран показывает чеклист, а не «почему-то пусто».
  Map<SpecFeature, FeatureGate> _buildGates({
    required PlatformFilesSource source,
    required List<Group> groups,
    required StatusSemantics semantics,
    required List<String> stacks,
    required Set<String> exampleKeys,
    required EnvReport envValues,
  }) {
    final env = source.loadEnv();
    final hasGrouping =
        groups.any((group) => group.kind != GroupingKind.none);
    final buildsFile = groups
        .where((group) => group.builds.isNotEmpty)
        .map((group) => group.id)
        .firstOrNull;
    final handover = [?_handoverCommand(source)];
    final recipients = source.recipientsScript;
    final services = source.allServices();
    final gitlabCheck = envValues.systems
        .where((check) => check.name == 'GitLab')
        .firstOrNull;
    final chatKeys =
        exampleKeys.where((key) => key.startsWith('MATTERMOST')).toList();

    return {
      SpecFeature.handoff: FeatureGate([
        FeatureRequirement(
          id: RequirementId.grouping,
          scope: RequirementScope.spec,
          satisfied: hasGrouping,
          lookedIn: 'openspec/doc/*',
        ),
        FeatureRequirement(
          id: RequirementId.statusSemantics,
          scope: RequirementScope.spec,
          satisfied: !semantics.isEmpty,
          lookedIn: 'openspec/redmine.yaml → sync.on_*_status_id',
        ),
        FeatureRequirement(
          id: RequirementId.buildsFile,
          scope: RequirementScope.spec,
          satisfied: buildsFile != null,
          optional: true,
          lookedIn: 'builds.yaml',
        ),
        FeatureRequirement(
          id: RequirementId.recipientsScript,
          scope: RequirementScope.spec,
          satisfied: recipients != null,
          optional: true,
          lookedIn: recipients ?? 'scripts/*handover*recipient*',
        ),
        // Обязательное: команда передачи — то, чем передача вообще
        // выполняется. Без неё шаги посчитают готовность и подберут
        // получателей, а отправлять будет нечем, и кнопка отправки
        // запустила бы команду, которой у спеки нет.
        FeatureRequirement(
          id: RequirementId.handoverCommand,
          scope: RequirementScope.spec,
          satisfied: handover.isNotEmpty,
          lookedIn: handover.map((command) => command.invocation).firstOrNull ??
              '.claude/commands, openspec/schemas/*/commands',
        ),
      ]),
      SpecFeature.builds: FeatureGate([
        FeatureRequirement(
          id: RequirementId.buildsFile,
          scope: RequirementScope.spec,
          satisfied: buildsFile != null,
          lookedIn: 'builds.yaml',
        ),
      ]),
      SpecFeature.mergeRequests: FeatureGate([
        FeatureRequirement(
          id: RequirementId.gitlabTokenDeclared,
          scope: RequirementScope.spec,
          satisfied: exampleKeys.contains('GITLAB_TOKEN'),
          lookedIn: 'GITLAB_TOKEN · .env.example',
        ),
        FeatureRequirement(
          id: RequirementId.services,
          scope: RequirementScope.spec,
          satisfied: services.isNotEmpty,
          lookedIn: 'workspace.yaml → services',
        ),
        FeatureRequirement(
          id: RequirementId.gitlabTokenFilled,
          scope: RequirementScope.personal,
          satisfied: (env['GITLAB_TOKEN'] ?? '').isNotEmpty,
          lookedIn: 'GITLAB_TOKEN · .env',
          keys: const ['GITLAB_TOKEN'],
        ),
        FeatureRequirement(
          id: RequirementId.gitlabReachable,
          scope: RequirementScope.runtime,
          // Предупреждение «не настроено» — это про предыдущие требования,
          // а не про доступность самого GitLab.
          satisfied:
              gitlabCheck == null || gitlabCheck.level != CheckLevel.error,
          lookedIn: gitlabCheck?.subtitle ?? '',
          detail: gitlabCheck == null || gitlabCheck.level == CheckLevel.ok
              ? ''
              : gitlabCheck.outcome.name,
        ),
      ]),
      SpecFeature.chat: FeatureGate([
        FeatureRequirement(
          id: RequirementId.chatKeysDeclared,
          scope: RequirementScope.spec,
          satisfied: chatKeys.isNotEmpty,
          lookedIn: 'MATTERMOST_* · .env.example',
        ),
        FeatureRequirement(
          id: RequirementId.chatKeysFilled,
          scope: RequirementScope.personal,
          satisfied: chatKeys.isNotEmpty &&
              chatKeys.every((key) => (env[key] ?? '').isNotEmpty),
          lookedIn: 'MATTERMOST_* · .env',
          keys: [
            for (final key in chatKeys)
              if ((env[key] ?? '').isEmpty) key,
          ],
        ),
      ]),
      SpecFeature.multiStack: FeatureGate([
        FeatureRequirement(
          id: RequirementId.stacks,
          scope: RequirementScope.spec,
          satisfied: stacks.length >= 2,
          lookedIn: 'openspec/schemas/*/schema.yaml → tasks-<stack>',
        ),
      ]),
    };
  }

  /// «git@host:group/project.git» → «https://host/group/project»:
  /// ссылка на ветку собирается без обращения к API.
  String _webUrlOfRepo(String repoUrl) {
    final match =
        RegExp(r'^(?:git@|https?://)([^:/]+)[:/](.+?)(?:\.git)?$')
            .firstMatch(repoUrl.trim());
    return match == null
        ? ''
        : 'https://${match.group(1)}/${match.group(2)}';
  }

  /// Живые статусы трекера: при отказе показываются закэшированные
  /// в redmine.yaml change'а, поэтому отказ — не пустой экран.
  Future<(RedmineProblem, String)> _fetchStatuses(
      PlatformFilesSource source, List<ChangeUnit> changes) async {
    final env = source.loadEnv();
    final baseUrl = env['REDMINE_URL'] ?? '';
    final apiKey = env['REDMINE_API_KEY'] ?? '';
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      return (RedmineProblem.noApiKey, '');
    }
    final issueIds = changes
        .expand((change) => change.stacks)
        .map((stack) => stack.issueId)
        .nonNulls
        .toList();
    try {
      final statuses = await RedmineApi(baseUrl, apiKey).issueStatuses(issueIds);
      for (final stack in changes.expand((change) => change.stacks)) {
        stack.liveStatus = statuses[stack.issueId];
      }
      return (RedmineProblem.none, '');
    } on DioException catch (error) {
      return (RedmineProblem.unreachable, error.message ?? error.type.name);
    } catch (error) {
      return (RedmineProblem.unreachable, '$error');
    }
  }

  Future<EnvReport> _buildEnvReport(PlatformFilesSource source) async {
    final env = source.loadEnv();
    return EnvReport(
      keys: _checkEnvKeys(source, env),
      repos: await _checkRepos(source),
      systems: await _checkSystems(env),
      backend: await secrets.backend(),
    );
  }

  /// Ключи строятся из `.env.example` целиком: белый список скрыл бы ключи
  /// чужой спеки (у avelacom — REDMINE_PROJECT_ID и OPENSPEC_REPO_URL).
  List<EnvCheck> _checkEnvKeys(
      PlatformFilesSource source, Map<String, String> env) {
    return [
      for (final example in source.loadEnvExampleKeys())
        _checkEnvKey(example, env[example.key] ?? ''),
    ];
  }

  EnvCheck _checkEnvKey(EnvKeyHint example, String value) {
    final key = example.key;
    if (value.isEmpty) {
      return EnvCheck(
          // Закомментированный в примере ключ — необязательный.
          level: example.optional ? CheckLevel.warn : CheckLevel.error,
          name: key,
          subtitle: example.hint,
          outcome: CheckOutcome.keyMissing);
    }
    if (key.endsWith('_ROLE')) {
      return EnvCheck(
          level: CheckLevel.ok,
          name: key,
          subtitle: example.hint,
          outcome: CheckOutcome.roleValue,
          param: value);
    }
    return EnvCheck(
        level: CheckLevel.ok,
        name: key,
        subtitle: example.hint,
        outcome: CheckOutcome.keyFilled);
  }

  Future<List<EnvCheck>> _checkRepos(PlatformFilesSource source) async {
    final serviceChecks = source.workspaceServices().map((service) async {
      final info = await source.workspaceGitInfo(service.name);
      return info == null
          ? EnvCheck(
              level: CheckLevel.error,
              name: service.name,
              subtitle: service.ref,
              outcome: CheckOutcome.repoNotCloned)
          : _gitCheck(service.name, info);
    });
    final platformInfo = await source.platformGitInfo();
    return [
      if (platformInfo != null) _gitCheck(source.specName, platformInfo),
      ...await Future.wait(serviceChecks),
    ];
  }

  EnvCheck _gitCheck(String repoName, ({String branch, int behind}) info) =>
      EnvCheck(
        level: info.behind > 0 ? CheckLevel.warn : CheckLevel.ok,
        name: repoName,
        subtitle: info.branch,
        outcome: info.behind > 0
            ? CheckOutcome.repoBehind
            : CheckOutcome.repoSynced,
        count: info.behind,
      );

  Future<List<EnvCheck>> _checkSystems(Map<String, String> env) =>
      Future.wait([
        _pingSystem('Redmine', env['REDMINE_URL'],
            (url) => RedmineApi(url, env['REDMINE_API_KEY'] ?? '').ping()),
        _pingSystem('GitLab', env['GITLAB_URL'],
            (url) => _timedGet('$url/api/v4/projects?per_page=1', headers: {
                  'PRIVATE-TOKEN': env['GITLAB_TOKEN'] ?? '',
                })),
        _pingSystem('Mattermost', env['MATTERMOST_URL'],
            (url) => _timedGet('$url/api/v4/system/ping')),
      ]);

  Future<int> _timedGet(String url, {Map<String, String>? headers}) async {
    final stopwatch = Stopwatch()..start();
    await Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: headers,
    )).get(url);
    return stopwatch.elapsedMilliseconds;
  }

  Future<EnvCheck> _pingSystem(String systemName, String? url,
      Future<int> Function(String url) request) async {
    if (url == null || url.isEmpty) {
      return EnvCheck(
          level: CheckLevel.warn,
          name: systemName,
          outcome: CheckOutcome.systemNotConfigured);
    }
    final host = Uri.tryParse(url)?.host ?? url;
    try {
      final milliseconds = await request(url);
      return EnvCheck(
          level: CheckLevel.ok,
          name: systemName,
          subtitle: host,
          outcome: CheckOutcome.systemResponds,
          count: milliseconds);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode < 500) {
        // Система жива; неверный ключ — уже другой уровень проблемы.
        return EnvCheck(
            level: CheckLevel.ok,
            name: systemName,
            subtitle: host,
            outcome: CheckOutcome.systemRespondsWithCode,
            count: statusCode);
      }
      return EnvCheck(
          level: CheckLevel.error,
          name: systemName,
          subtitle: host,
          outcome: error.type == DioExceptionType.connectionTimeout
              ? CheckOutcome.systemTimeout
              : CheckOutcome.systemNoConnection);
    }
  }
}
