import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:platform_console/domain/entities/entities.dart';

/// Чтение файлов avtoto-platform. Ничего не пишет и не кэширует на диске.
class PlatformFilesSource {
  final Directory root;
  PlatformFilesSource(this.root);

  /// Ищет репозиторий платформы: $AVTOTO_PLATFORM_DIR, затем типовые пути.
  static PlatformFilesSource? locate() {
    final candidates = <String>[
      if (Platform.environment['AVTOTO_PLATFORM_DIR'] != null)
        Platform.environment['AVTOTO_PLATFORM_DIR']!,
      '${Platform.environment['HOME']}/webAnt-poject/avtoto-platform',
      '${Platform.environment['HOME']}/webant-project/avtoto-platform',
      '${Platform.environment['HOME']}/avtoto-platform',
    ];
    for (final p in candidates) {
      final d = Directory(p);
      if (File('${d.path}/workspace.yaml').existsSync()) return PlatformFilesSource(d);
    }
    return null;
  }

  String get path => root.path;
  File _file(String rel) => File('${root.path}/$rel');
  Directory _dir(String rel) => Directory('${root.path}/$rel');

  // ─── Спринты ───────────────────────────────────────────────────────────────

  List<Sprint> loadSprints() {
    final docDir = _dir('openspec/doc');
    if (!docDir.existsSync()) return [];
    final sprints = <Sprint>[];
    for (final e in docDir.listSync().whereType<Directory>()) {
      final id = e.path.split('/').last;
      sprints.add(_loadSprint(id, e));
    }
    sprints.sort((a, b) => a.id.compareTo(b.id));
    return sprints;
  }

  Sprint _loadSprint(String id, Directory dir) {
    var title = id;
    final doc = File('${dir.path}/doc.md');
    if (doc.existsSync()) {
      final first = doc.readAsLinesSync().firstWhere(
          (l) => l.startsWith('# '),
          orElse: () => '# $id');
      // «# pin-biometric-auth — Название: master-spec»
      final m = RegExp(r'^#\s*\S+\s*—\s*(.+?)(:\s*master-spec)?\s*$')
          .firstMatch(first);
      if (m != null) title = m.group(1)!;
    }

    String? branchIos, branchAndroid;
    var delivery = 'batch';
    final sy = File('${dir.path}/sprint.yaml');
    if (sy.existsSync()) {
      final y = loadYaml(sy.readAsStringSync());
      branchIos = y['branches']?['ios']?['name']?.toString();
      branchAndroid = y['branches']?['android']?['name']?.toString();
      delivery = y['delivery']?.toString() ?? 'batch';
    }

    BuildInfo? bIos, bAndroid;
    final by = File('${dir.path}/builds.yaml');
    if (by.existsSync()) {
      final y = loadYaml(by.readAsStringSync());
      bIos = _buildInfo(y['ios'], iosChannel: true);
      bAndroid = _buildInfo(y['android'], iosChannel: false);
    }

    return Sprint(
      id: id,
      title: title,
      branchIos: branchIos,
      branchAndroid: branchAndroid,
      delivery: delivery,
      buildIos: bIos,
      buildAndroid: bAndroid,
    );
  }

  BuildInfo? _buildInfo(dynamic node, {required bool iosChannel}) {
    if (node == null) return null;
    final builds = node['builds'];
    if (builds is! YamlList || builds.isEmpty) return null;
    final b = builds.first;
    final name = iosChannel
        ? b['version_name']?.toString()
        : '${b['version_name']}(${b['version_code']})';
    return BuildInfo(
      versionName: name ?? '?',
      channel: b['channel']?.toString() ??
          (b['nextcloud_url'] != null ? 'QA APK в Nextcloud' : null),
      publishedAt: DateTime.tryParse(b['published_at']?.toString() ?? ''),
    );
  }

  // ─── Change'и ──────────────────────────────────────────────────────────────

  List<ChangeUnit> loadChanges() {
    final chDir = _dir('openspec/changes');
    if (!chDir.existsSync()) return [];
    final changes = <ChangeUnit>[];
    for (final e in chDir.listSync().whereType<Directory>()) {
      final id = e.path.split('/').last;
      if (id == 'archive') continue;
      changes.add(_loadChange(id, e));
    }
    // Порядок сдачи из group.members (у всех change'ей он общий).
    final order = <String, int>{};
    for (final c in changes) {
      for (var i = 0; i < c.dependsOn.length; i++) {
        order.putIfAbsent(c.dependsOn[i], () => i);
      }
    }
    changes.sort((a, b) =>
        (order[a.id] ?? 99).compareTo(order[b.id] ?? 99));
    return changes;
  }

  ChangeUnit _loadChange(String id, Directory dir) {
    int? iosIssue, androidIssue;
    var members = const <String>[];
    final ry = File('${dir.path}/redmine.yaml');
    if (ry.existsSync()) {
      final y = loadYaml(ry.readAsStringSync());
      iosIssue = int.tryParse('${y['stacks']?['ios']?['issue_id']}');
      androidIssue = int.tryParse('${y['stacks']?['android']?['issue_id']}');
      final g = y['group']?['members'];
      if (g is YamlList) members = g.map((e) => e.toString()).toList();
    }

    final iosTasks = _loadTasks(File('${dir.path}/tasks_ios.md'));
    final androidTasks = _loadTasks(File('${dir.path}/tasks_android.md'));
    final title = iosTasks.$2 ?? androidTasks.$2 ?? _proposalTitle(dir) ?? id;

    return ChangeUnit(
      id: id,
      title: title,
      dir: dir.path,
      ios: iosTasks.$1.isEmpty
          ? null
          : StackState(stack: 'ios', issueId: iosIssue, tasks: iosTasks.$1),
      android: androidTasks.$1.isEmpty
          ? null
          : StackState(
              stack: 'android', issueId: androidIssue, tasks: androidTasks.$1),
      dependsOn: members.takeWhile((m) => m != id).toList(),
    );
  }

  /// Возвращает (задачи, redmine_title из финального front-matter блока).
  (List<TaskItem>, String?) _loadTasks(File f) {
    if (!f.existsSync()) return (const [], null);
    final tasks = <TaskItem>[];
    String? title;
    for (final line in f.readAsLinesSync()) {
      final m = RegExp(r'^-\s*\[( |x)\]\s*(\d+\.\d+)\s+(.+)$').firstMatch(line);
      if (m != null) {
        tasks.add(TaskItem(m.group(2)!, m.group(3)!, m.group(1) == 'x'));
      }
      final t = RegExp(r'^redmine_title:\s*(.+)$').firstMatch(line);
      if (t != null) title = t.group(1)!.trim();
    }
    return (tasks, title);
  }

  String? _proposalTitle(Directory dir) {
    final f = File('${dir.path}/proposal.md');
    if (!f.existsSync()) return null;
    final first = f
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('# '), orElse: () => '');
    return first.isEmpty ? null : first.substring(2).trim();
  }

  // ─── Окружение ─────────────────────────────────────────────────────────────

  Map<String, String> loadEnv() {
    final env = <String, String>{};
    final f = _file('.env');
    if (!f.existsSync()) return env;
    for (final line in f.readAsLinesSync()) {
      final m = RegExp(r'^([A-Z0-9_]+)=(.*)$').firstMatch(line.trim());
      if (m != null) env[m.group(1)!] = m.group(2)!;
    }
    return env;
  }

  /// Ключи из .env.example — источник списка проверок (только имена).
  List<String> loadEnvExampleKeys() {
    final f = _file('.env.example');
    if (!f.existsSync()) return [];
    return [
      for (final line in f.readAsLinesSync())
        if (RegExp(r'^[A-Z0-9_]+=').hasMatch(line.trim()))
          line.trim().split('=').first
    ];
  }

  String get role => loadEnv()['AVTOTO_ROLE'] ?? '';

  /// Сервисы workspace.yaml, отфильтрованные по роли машины.
  List<({String name, String ref})> workspaceServices() {
    final f = _file('workspace.yaml');
    if (!f.existsSync()) return [];
    final y = loadYaml(f.readAsStringSync());
    final services = y['services'];
    if (services is! YamlList) return [];
    final r = role;
    final out = <({String name, String ref})>[];
    for (final s in services) {
      final roles = (s['roles']?.toString() ?? '')
          .split(',')
          .map((e) => e.trim())
          .toList();
      if (r.isEmpty || roles.contains(r) || roles.contains('dev') && r == 'dev') {
        if (r.isEmpty || roles.contains(r)) {
          out.add((name: s['name'].toString(), ref: s['ref'].toString()));
        }
      }
    }
    return out;
  }

  // ─── Git ───────────────────────────────────────────────────────────────────

  Future<({String branch, int behind})?> gitInfo(String repoDirName) async {
    final dir = '${root.path}/workspace/$repoDirName';
    if (!Directory(dir).existsSync()) return null;
    final branch = await _git(dir, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch == null) return null;
    final behindRaw =
        await _git(dir, ['rev-list', '--count', 'HEAD..@{upstream}']);
    return (branch: branch, behind: int.tryParse(behindRaw ?? '') ?? 0);
  }

  Future<({String branch, int behind})?> platformGitInfo() async {
    final branch = await _git(root.path, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch == null) return null;
    final behindRaw =
        await _git(root.path, ['rev-list', '--count', 'HEAD..@{upstream}']);
    return (branch: branch, behind: int.tryParse(behindRaw ?? '') ?? 0);
  }

  Future<String?> _git(String dir, List<String> args) async {
    try {
      final r = await Process.run('git', ['-C', dir, ...args]);
      if (r.exitCode != 0) return null;
      return (r.stdout as String).trim();
    } catch (_) {
      return null;
    }
  }
}
