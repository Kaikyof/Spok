import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/snapshot.dart';
import '../../domain/repositories/platform_repository.dart';
import '../sources/platform_files_source.dart';
import '../sources/redmine_api.dart';

class PlatformRepositoryImpl implements PlatformRepository {
  final PlatformFilesSource? files;
  PlatformRepositoryImpl(this.files);

  @override
  String? get rootPath => files?.path;

  @override
  String get role => files?.role ?? '';

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
    final f = files;
    if (f == null) {
      return ConsoleSnapshot(
        sprints: const [],
        changes: const [],
        divergences: const [],
        env: EnvReport(keys: const [], repos: const [], systems: const []),
        redmineProblem: 'репозиторий платформы не найден',
        refreshedAt: DateTime.now(),
      );
    }

    final sprints = f.loadSprints();
    final changes = f.loadChanges();
    final redmineProblem = await _fetchStatuses(f, changes);
    final divergences =
        findDivergences(sprints.firstOrNull, changes);
    final env = await _buildEnvReport(f);

    return ConsoleSnapshot(
      sprints: sprints,
      changes: changes,
      divergences: divergences,
      env: env,
      redmineProblem: redmineProblem,
      refreshedAt: DateTime.now(),
    );
  }

  Future<String?> _fetchStatuses(
      PlatformFilesSource f, List<ChangeUnit> changes) async {
    final env = f.loadEnv();
    final url = env['REDMINE_URL'] ?? '';
    final key = env['REDMINE_API_KEY'] ?? '';
    if (url.isEmpty || key.isEmpty) return 'нет ключа REDMINE_API_KEY';
    final ids = [
      for (final c in changes)
        for (final s in c.stacks)
          if (s.issueId != null) s.issueId!,
    ];
    try {
      final statuses = await RedmineApi(url, key).issueStatuses(ids);
      for (final c in changes) {
        for (final s in c.stacks) {
          s.redmineStatus = statuses[s.issueId];
        }
      }
      return null;
    } on DioException catch (e) {
      return 'Redmine недоступен: ${e.message ?? e.type.name}';
    } catch (e) {
      return 'Redmine недоступен: $e';
    }
  }

  Future<EnvReport> _buildEnvReport(PlatformFilesSource f) async {
    final env = f.loadEnv();

    const hints = {
      'REDMINE_URL': 'адрес Redmine',
      'REDMINE_API_KEY': 'доступ к задачам',
      'GITLAB_URL': 'адрес GitLab',
      'GITLAB_TOKEN': 'доступ к MR и веткам',
      'MATTERMOST_URL': 'адрес Mattermost',
      'MATTERMOST_BOT_TOKEN': 'бот уведомлений',
      'MATTERMOST_DEVELOPERS_CHANNEL_ID': 'канал разработчиков',
      'MATTERMOST_TEAM_CHANNEL_ID': 'канал команды — уведомление о передаче',
      'AVTOTO_ROLE': 'роль машины',
    };

    final keys = <EnvCheck>[
      for (final k in f.loadEnvExampleKeys().where(hints.containsKey))
        (env[k] ?? '').isNotEmpty
            ? EnvCheck(CheckLevel.ok, k, hints[k]!,
                k == 'AVTOTO_ROLE' ? env[k]! : 'заполнен')
            : EnvCheck(
                CheckLevel.error, k, hints[k]!, 'отсутствует — добавьте в .env'),
    ];

    final repos = <EnvCheck>[];
    final pg = await f.platformGitInfo();
    if (pg != null) repos.add(_gitCheck('avtoto-platform', pg));
    for (final s in f.workspaceServices()) {
      final gi = await f.gitInfo(s.name);
      repos.add(gi == null
          ? EnvCheck(CheckLevel.error, s.name, 'ожидается ${s.ref}',
              'не склонирован — make init')
          : _gitCheck(s.name, gi));
    }

    final systems = <EnvCheck>[
      await _ping('Redmine', env['REDMINE_URL'],
          (url) => RedmineApi(url, env['REDMINE_API_KEY'] ?? '').ping()),
      await _ping('GitLab', env['GITLAB_URL'], (url) async {
        final sw = Stopwatch()..start();
        await Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                headers: {'PRIVATE-TOKEN': env['GITLAB_TOKEN'] ?? ''}))
            .get('$url/api/v4/projects?per_page=1');
        return sw.elapsedMilliseconds;
      }),
      await _ping('Mattermost', env['MATTERMOST_URL'], (url) async {
        final sw = Stopwatch()..start();
        await Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)))
            .get('$url/api/v4/system/ping');
        return sw.elapsedMilliseconds;
      }),
    ];

    return EnvReport(keys: keys, repos: repos, systems: systems);
  }

  EnvCheck _gitCheck(String name, ({String branch, int behind}) gi) => EnvCheck(
        gi.behind > 0 ? CheckLevel.warn : CheckLevel.ok,
        name,
        gi.branch,
        gi.behind > 0 ? 'отстаёт от origin на ${gi.behind}' : 'синхронизирован',
      );

  Future<EnvCheck> _ping(
      String name, String? url, Future<int> Function(String) call) async {
    if (url == null || url.isEmpty) {
      return EnvCheck(
          CheckLevel.warn, name, 'не проверялся', 'адрес не задан в .env');
    }
    final host = Uri.tryParse(url)?.host ?? url;
    try {
      final ms = await call(url);
      return EnvCheck(CheckLevel.ok, name, host, 'отвечает · $ms мс');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != null && code < 500) {
        // Система жива, ключ может быть неверным — это уже другой уровень.
        return EnvCheck(CheckLevel.ok, name, host, 'отвечает · код $code');
      }
      return EnvCheck(CheckLevel.error, name, host,
          e.type == DioExceptionType.connectionTimeout ? 'таймаут 8 с' : 'нет соединения');
    } catch (e) {
      return EnvCheck(CheckLevel.error, name, host, '$e');
    }
  }
}

/// Правила расхождений: сравнение ярлыка (Redmine) с фактом (файлы, сборки).
/// Чистая функция — расширяется новыми правилами без изменения слоёв.
List<Divergence> findDivergences(Sprint? sprint, List<ChangeUnit> changes) {
  final out = <Divergence>[];
  for (final c in changes) {
    for (final s in c.stacks) {
      final status = s.redmineStatus;
      if (status == null || s.tasks.isEmpty) continue;
      final full = s.openTasks.isEmpty;
      if (full &&
          ['Новая', 'В работе', 'Возвращена с ревью', 'Возвращена']
              .contains(status)) {
        out.add(Divergence(c.id, c.title, s.stack,
            'галочки ${s.doneCount}/${s.tasks.length}, но задача в статусе «$status»'));
      }
      if (!full &&
          ['Ожидает тестирования', 'На тестировании', 'Готово к релизу']
              .contains(status)) {
        final open = s.openTasks.map((t) => t.num).join(', ');
        out.add(Divergence(c.id, c.title, s.stack,
            'статус «$status», но не закрыты задачи $open'));
      }
    }
  }
  if (sprint != null) {
    final waiting = changes.any(
        (c) => c.stacks.any((s) => s.redmineStatus == 'Ожидает тестирования'));
    if (waiting && sprint.buildIos == null) {
      out.add(Divergence(sprint.id, sprint.title, 'ios',
          'есть задачи в «Ожидает тестирования», но сборка iOS не записана'));
    }
    if (waiting && sprint.buildAndroid == null) {
      out.add(Divergence(sprint.id, sprint.title, 'android',
          'есть задачи в «Ожидает тестирования», но сборка Android не записана'));
    }
  }
  return out;
}
