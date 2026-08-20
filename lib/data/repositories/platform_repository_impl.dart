import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/change_unit.dart';
import '../../domain/entities/console_snapshot.dart';
import '../../domain/entities/env_check.dart';
import '../../domain/entities/env_report.dart';
import '../../domain/usecases/find_divergences.dart';
import '../../domain/repositories/platform_repository.dart';
import '../sources/app_config_source.dart';
import '../sources/platform_files_source.dart';
import '../sources/redmine_api.dart';

/// Ключи .env, критичные для работы консоли, — в порядке показа.
const _criticalEnvKeys = [
  'REDMINE_URL',
  'REDMINE_API_KEY',
  'GITLAB_URL',
  'GITLAB_TOKEN',
  'MATTERMOST_URL',
  'MATTERMOST_BOT_TOKEN',
  'MATTERMOST_DEVELOPERS_CHANNEL_ID',
  'MATTERMOST_TEAM_CHANNEL_ID',
  'AVTOTO_ROLE',
];

class PlatformRepositoryImpl implements PlatformRepository {
  PlatformFilesSource? files;
  final AppConfigSource config;
  final FindDivergences findDivergences;

  PlatformRepositoryImpl(this.files,
      {AppConfigSource? config, FindDivergences? findDivergences})
      : config = config ?? AppConfigSource(),
        findDivergences = findDivergences ?? FindDivergences();

  /// Ищет платформу с учётом пути, сохранённого в конфиге приложения.
  static Future<PlatformRepositoryImpl> create() async {
    final config = AppConfigSource();
    final configuredPath = await config.readPlatformDir();
    return PlatformRepositoryImpl(
      PlatformFilesSource.locate(configuredPath: configuredPath),
      config: config,
    );
  }

  @override
  String? get rootPath => files?.path;

  @override
  String get role => files?.role ?? '';

  @override
  Future<String> configFilePath() => config.configPath();

  @override
  Future<bool> setPlatformDir(String path) async {
    final trimmedPath = path.trim();
    if (!PlatformFilesSource.isPlatformRoot(trimmedPath)) return false;
    await config.writePlatformDir(trimmedPath);
    files = PlatformFilesSource(Directory(trimmedPath));
    return true;
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
  Future<ConsoleSnapshot> load() async {
    final source = files;
    if (source == null) {
      return ConsoleSnapshot(
        sprints: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        redmineProblem: RedmineProblem.platformNotFound,
        refreshedAt: DateTime.now(),
      );
    }

    final sprints = source.loadSprints();
    final changes = source.loadChanges();
    final (redmineProblem, redmineDetail) =
        await _fetchStatuses(source, changes);

    return ConsoleSnapshot(
      sprints: sprints,
      changes: changes,
      divergences: findDivergences(sprints.firstOrNull, changes),
      env: await _buildEnvReport(source),
      redmineProblem: redmineProblem,
      redmineProblemDetail: redmineDetail,
      redmineBaseUrl: source.loadEnv()['REDMINE_URL'] ?? '',
      refreshedAt: DateTime.now(),
    );
  }

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
        stack.redmineStatus = statuses[stack.issueId];
      }
      return (RedmineProblem.none, '');
    } on DioException catch (error) {
      return (RedmineProblem.unreachable, error.message ?? error.type.name);
    } catch (error) {
      return (RedmineProblem.unreachable, '$error');
    }
  }

  // ─── Окружение ─────────────────────────────────────────────────────────────

  Future<EnvReport> _buildEnvReport(PlatformFilesSource source) async {
    final env = source.loadEnv();
    return EnvReport(
      keys: _checkEnvKeys(source, env),
      repos: await _checkRepos(source),
      systems: await _checkSystems(env),
    );
  }

  List<EnvCheck> _checkEnvKeys(
      PlatformFilesSource source, Map<String, String> env) {
    final exampleKeys = source.loadEnvExampleKeys();
    return [
      for (final key in _criticalEnvKeys.where(exampleKeys.contains))
        _checkEnvKey(key, env[key] ?? ''),
    ];
  }

  EnvCheck _checkEnvKey(String key, String value) {
    if (value.isEmpty) {
      return EnvCheck(
          level: CheckLevel.error, name: key, outcome: CheckOutcome.keyMissing);
    }
    if (key == 'AVTOTO_ROLE') {
      return EnvCheck(
          level: CheckLevel.ok,
          name: key,
          outcome: CheckOutcome.roleValue,
          param: value);
    }
    return EnvCheck(
        level: CheckLevel.ok, name: key, outcome: CheckOutcome.keyFilled);
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
      if (platformInfo != null) _gitCheck('avtoto-platform', platformInfo),
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
