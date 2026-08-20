import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../domain/entities/build_info.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/repositories/command_log.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/entities/sprint.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';

/// Чтение файлов avtoto-platform. Ничего не пишет и не кэширует на диске.
class PlatformFilesSource {
  final Directory root;

  /// Журнал команд для панели запуска; без него источник работает молча.
  final CommandLog? commandLog;

  PlatformFilesSource(this.root, {this.commandLog});

  /// Проверка, что каталог — корень платформы.
  static bool isPlatformRoot(String dir) =>
      File(p.join(dir, 'workspace.yaml')).existsSync();

  /// Ищет репозиторий платформы: переменная окружения AVTOTO_PLATFORM_DIR,
  /// путь из конфига приложения, затем типовые пути.
  static PlatformFilesSource? locate(
      {String? configuredPath, CommandLog? commandLog}) {
    final home = Platform.environment['HOME'];
    final candidates = [
      ?Platform.environment['AVTOTO_PLATFORM_DIR'],
      ?configuredPath,
      '$home/webAnt-poject/avtoto-platform',
      '$home/webant-project/avtoto-platform',
      '$home/avtoto-platform',
    ];
    for (final candidate in candidates) {
      if (isPlatformRoot(candidate)) {
        return PlatformFilesSource(Directory(candidate),
            commandLog: commandLog);
      }
    }
    return null;
  }

  String get path => root.path;

  // ─── Спринты ───────────────────────────────────────────────────────────────

  List<Sprint> loadSprints() {
    final docDir = Directory(p.join(root.path, 'openspec', 'doc'));
    if (!docDir.existsSync()) return [];
    final sprints = [
      for (final entry in docDir.listSync().whereType<Directory>())
        _loadSprint(p.basename(entry.path), entry),
    ];
    sprints.sort((a, b) => a.id.compareTo(b.id));
    return sprints;
  }

  Sprint _loadSprint(String sprintId, Directory sprintDir) => Sprint(
        id: sprintId,
        title: _sprintTitle(sprintId, sprintDir),
        branchIos: _sprintYamlValue(sprintDir, ['branches', 'ios', 'name']),
        branchAndroid:
            _sprintYamlValue(sprintDir, ['branches', 'android', 'name']),
        delivery: _sprintYamlValue(sprintDir, ['delivery']) ?? 'batch',
        buildIos: _latestBuild(sprintDir, 'ios'),
        buildAndroid: _latestBuild(sprintDir, 'android'),
      );

  String _sprintTitle(String sprintId, Directory sprintDir) {
    final docFile = File(p.join(sprintDir.path, 'doc.md'));
    if (!docFile.existsSync()) return sprintId;
    final heading = docFile.readAsLinesSync().firstWhere(
        (line) => line.startsWith('# '),
        orElse: () => '# $sprintId');
    // «# pin-biometric-auth — Название: master-spec»
    final match = RegExp(r'^#\s*\S+\s*—\s*(.+?)(:\s*master-spec)?\s*$')
        .firstMatch(heading);
    return match?.group(1) ?? sprintId;
  }

  String? _sprintYamlValue(Directory sprintDir, List<String> keyPath) {
    final file = File(p.join(sprintDir.path, 'sprint.yaml'));
    if (!file.existsSync()) return null;
    dynamic node = loadYaml(file.readAsStringSync());
    for (final key in keyPath) {
      node = node?[key];
    }
    return node?.toString();
  }

  BuildInfo? _latestBuild(Directory sprintDir, String stack) {
    final file = File(p.join(sprintDir.path, 'builds.yaml'));
    if (!file.existsSync()) return null;
    final builds = loadYaml(file.readAsStringSync())[stack]?['builds'];
    if (builds is! YamlList || builds.isEmpty) return null;
    final build = builds.first;
    final versionName = stack == 'ios'
        ? build['version_name']?.toString()
        : '${build['version_name']}(${build['version_code']})';
    return BuildInfo(
      versionName: versionName ?? '?',
      channel: build['channel']?.toString() ??
          (build['nextcloud_url'] != null ? 'QA APK в Nextcloud' : null),
      publishedAt: DateTime.tryParse(build['published_at']?.toString() ?? ''),
    );
  }

  // ─── Change'и ──────────────────────────────────────────────────────────────

  List<ChangeUnit> loadChanges() {
    final changesDir = Directory(p.join(root.path, 'openspec', 'changes'));
    if (!changesDir.existsSync()) return [];
    final changes = [
      for (final entry in changesDir.listSync().whereType<Directory>())
        if (p.basename(entry.path) != 'archive')
          _loadChange(p.basename(entry.path), entry),
    ];
    _sortByDeliveryOrder(changes);
    return changes;
  }

  /// Порядок сдачи задан списком group.members — он общий у всех change'ей.
  void _sortByDeliveryOrder(List<ChangeUnit> changes) {
    final deliveryOrder = <String, int>{};
    for (final change in changes) {
      for (final (index, memberId) in change.dependsOn.indexed) {
        deliveryOrder.putIfAbsent(memberId, () => index);
      }
    }
    changes.sort((a, b) =>
        (deliveryOrder[a.id] ?? 99).compareTo(deliveryOrder[b.id] ?? 99));
  }

  ChangeUnit _loadChange(String changeId, Directory changeDir) {
    final links = _loadRedmineLinks(changeDir);
    final (iosTasks, iosTitle) =
        _loadTasksFile(File(p.join(changeDir.path, 'tasks_ios.md')));
    final (androidTasks, androidTitle) =
        _loadTasksFile(File(p.join(changeDir.path, 'tasks_android.md')));

    return ChangeUnit(
      id: changeId,
      title: iosTitle ?? androidTitle ?? _proposalTitle(changeDir) ?? changeId,
      dir: changeDir.path,
      ios: iosTasks.isEmpty
          ? null
          : StackState(stack: 'ios', issueId: links.iosIssue, tasks: iosTasks),
      android: androidTasks.isEmpty
          ? null
          : StackState(
              stack: 'android',
              issueId: links.androidIssue,
              tasks: androidTasks),
      dependsOn:
          links.members.takeWhile((member) => member != changeId).toList(),
    );
  }

  ({int? iosIssue, int? androidIssue, List<String> members}) _loadRedmineLinks(
      Directory changeDir) {
    final file = File(p.join(changeDir.path, 'redmine.yaml'));
    if (!file.existsSync()) {
      return (iosIssue: null, androidIssue: null, members: const []);
    }
    final yaml = loadYaml(file.readAsStringSync());
    final members = yaml['group']?['members'];
    return (
      iosIssue: int.tryParse('${yaml['stacks']?['ios']?['issue_id']}'),
      androidIssue: int.tryParse('${yaml['stacks']?['android']?['issue_id']}'),
      members: members is YamlList
          ? members.map((member) => member.toString()).toList()
          : const <String>[],
    );
  }

  /// Возвращает (задачи, redmine_title из финального front-matter блока).
  (List<TaskItem>, String?) _loadTasksFile(File file) {
    if (!file.existsSync()) return (const [], null);
    final tasks = <TaskItem>[];
    String? redmineTitle;
    final checkboxPattern = RegExp(r'^-\s*\[( |x)\]\s*(\d+\.\d+)\s+(.+)$');
    final titlePattern = RegExp(r'^redmine_title:\s*(.+)$');
    for (final line in file.readAsLinesSync()) {
      final checkbox = checkboxPattern.firstMatch(line);
      if (checkbox != null) {
        tasks.add(TaskItem(
            checkbox.group(2)!, checkbox.group(3)!, checkbox.group(1) == 'x'));
      }
      redmineTitle =
          titlePattern.firstMatch(line)?.group(1)?.trim() ?? redmineTitle;
    }
    return (tasks, redmineTitle);
  }

  String? _proposalTitle(Directory changeDir) {
    final file = File(p.join(changeDir.path, 'proposal.md'));
    if (!file.existsSync()) return null;
    final heading = file
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('# '), orElse: () => '');
    return heading.isEmpty ? null : heading.substring(2).trim();
  }

  // ─── Окружение ─────────────────────────────────────────────────────────────

  Map<String, String> loadEnv() {
    final file = File(p.join(root.path, '.env'));
    if (!file.existsSync()) return {};
    final entryPattern = RegExp(r'^([A-Z0-9_]+)=(.*)$');
    return {
      for (final line in file.readAsLinesSync())
        if (entryPattern.firstMatch(line.trim()) case final match?)
          match.group(1)!: match.group(2)!,
    };
  }

  /// Ключи из .env.example — источник списка проверок (только имена).
  List<String> loadEnvExampleKeys() {
    final file = File(p.join(root.path, '.env.example'));
    if (!file.existsSync()) return [];
    final keyPattern = RegExp(r'^[A-Z0-9_]+=');
    return [
      for (final line in file.readAsLinesSync())
        if (keyPattern.hasMatch(line.trim())) line.trim().split('=').first,
    ];
  }

  String get role => loadEnv()['AVTOTO_ROLE'] ?? '';

  /// Сервисы workspace.yaml, отфильтрованные по роли машины.
  List<({String name, String ref})> workspaceServices() {
    final file = File(p.join(root.path, 'workspace.yaml'));
    if (!file.existsSync()) return [];
    final services = loadYaml(file.readAsStringSync())['services'];
    if (services is! YamlList) return [];
    final machineRole = role;
    return [
      for (final service in services)
        if (_serviceMatchesRole(service, machineRole))
          (name: service['name'].toString(), ref: service['ref'].toString()),
    ];
  }

  bool _serviceMatchesRole(dynamic service, String machineRole) {
    if (machineRole.isEmpty) return true;
    final serviceRoles =
        (service['roles']?.toString() ?? '').split(',').map((r) => r.trim());
    return serviceRoles.contains(machineRole);
  }

  // ─── Команды платформы ─────────────────────────────────────────────────────

  /// Команды из `.claude/commands/*.md` — тот же источник, что у автокомплита
  /// в терминале: id, description и argument-hint из frontmatter.
  List<SlashCommand> loadSlashCommands() {
    final commandsDir = Directory(p.join(root.path, '.claude', 'commands'));
    if (!commandsDir.existsSync()) return [];
    final commands = [
      for (final entry in commandsDir.listSync().whereType<File>())
        if (entry.path.endsWith('.md')) _loadSlashCommand(entry),
    ].nonNulls.toList();
    commands.sort((a, b) => a.id.compareTo(b.id));
    return commands;
  }

  SlashCommand? _loadSlashCommand(File file) {
    final frontmatter = <String, String>{};
    var insideFrontmatter = false;
    final fieldPattern = RegExp(r'^([a-z-]+):\s*(.*)$');
    for (final line in file.readAsLinesSync()) {
      if (line.trim() == '---') {
        if (insideFrontmatter) break;
        insideFrontmatter = true;
        continue;
      }
      if (!insideFrontmatter) continue;
      final match = fieldPattern.firstMatch(line);
      if (match != null) frontmatter[match.group(1)!] = match.group(2)!.trim();
    }
    final id = frontmatter['id'] ?? p.basenameWithoutExtension(file.path);
    final description = frontmatter['description'] ?? '';
    if (description.isEmpty) return null;
    return SlashCommand(
      id: id,
      description: description,
      argumentHint: frontmatter['argument-hint'] ?? '',
    );
  }

  // ─── Git ───────────────────────────────────────────────────────────────────

  /// Подтягивает свежие изменения платформы перед чтением: спеки и чеклисты
  /// правят коллеги, без pull кнопка «Обновить» показывала бы вчерашнее.
  /// Только fast-forward; любая ошибка (офлайн, локальные правки) не мешает
  /// работе с тем, что есть на диске.
  Future<void> pullPlatform() async {
    final run = commandLog?.begin('git -C ${root.path} pull --ff-only');
    try {
      final result =
          await Process.run('git', ['-C', root.path, 'pull', '--ff-only'])
              .timeout(const Duration(seconds: 15));
      if (run != null) {
        commandLog?.complete(run,
            output: '${result.stdout}${result.stderr}'.trim(),
            exitCode: result.exitCode);
      }
    } catch (error) {
      // офлайн или конфликт — читаем локальное состояние
      if (run != null) {
        commandLog?.complete(run, output: '$error', exitCode: 1);
      }
    }
  }

  Future<({String branch, int behind})?> workspaceGitInfo(String repoDirName) =>
      _gitInfo(p.join(root.path, 'workspace', repoDirName));

  Future<({String branch, int behind})?> platformGitInfo() =>
      _gitInfo(root.path);

  Future<({String branch, int behind})?> _gitInfo(String repoDir) async {
    if (!Directory(repoDir).existsSync()) return null;
    final branch = await _git(repoDir, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch == null) return null;
    final behind =
        await _git(repoDir, ['rev-list', '--count', 'HEAD..@{upstream}']);
    return (branch: branch, behind: int.tryParse(behind ?? '') ?? 0);
  }

  Future<String?> _git(String repoDir, List<String> args) async {
    try {
      final result = await Process.run('git', ['-C', repoDir, ...args]);
      if (result.exitCode != 0) return null;
      return (result.stdout as String).trim();
    } catch (_) {
      return null;
    }
  }
}
