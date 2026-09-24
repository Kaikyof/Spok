import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../domain/entities/build_info.dart';
import '../../domain/entities/change_unit.dart';
import '../../domain/entities/doc_artifact.dart';
import '../../domain/entities/doc_node.dart';
import '../../domain/entities/doc_state.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/spec_schema.dart';
import '../../domain/entities/status_semantics.dart';
import '../../domain/repositories/command_log.dart';
import '../../domain/entities/slash_command.dart';
import '../../domain/entities/stack_state.dart';
import '../../domain/entities/task_item.dart';
import 'executable_locator.dart';
import 'env_file.dart';

/// Ключ .env с подсказкой из комментария над строкой в `.env.example`.
/// `optional` — ключ в примере закомментирован, спека работает и без него.
typedef EnvKeyHint = ({String key, String hint, bool optional});

/// Чтение файлов спеки (openspec-репозитория). Ничего не пишет и не кэширует
/// на диске. Имена файлов и стеки берутся из схемы спеки, а не зашиты в код.
class PlatformFilesSource {
  final Directory root;

  /// Журнал команд для панели запуска; без него источник работает молча.
  final CommandLog? commandLog;

  PlatformFilesSource(this.root, {this.commandLog});

  /// Проверка, что каталог — корень спеки.
  static bool isPlatformRoot(String dir) =>
      File(p.join(dir, 'workspace.yaml')).existsSync() ||
      Directory(p.join(dir, 'openspec')).existsSync();

  /// Ищет репозиторий спеки: переменные окружения, путь из конфига
  /// приложения, затем типовые пути.
  static PlatformFilesSource? locate(
      {String? configuredPath, CommandLog? commandLog}) {
    final home = Platform.environment['HOME'];
    final candidates = [
      ?Platform.environment['SPEC_PLATFORM_DIR'],
      ?Platform.environment['AVTOTO_PLATFORM_DIR'],
      ?configuredPath,
      '$home/webAnt-poject/avtoto-platform',
      '$home/webant-project/avtoto-platform',
      '$home/avtoto-platform',
      '$home/avelacom-platform',
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

  String get specName => p.basename(root.path);

  /// Файлы, по которым приложение разбирает устройство спеки. Нужны экрану
  /// «Что распознано»: правится устройство в самой спеке, и «изменить»
  /// открывает тот файл, который решает, а не тот, что похож по имени.
  /// Пустая строка — файла в этой спеке нет.
  String get schemaFile {
    final schemaName = _yamlValue(
        File(p.join(root.path, 'openspec', 'config.yaml')), ['schema']);
    if (schemaName == null) return '';
    final file = File(
        p.join(root.path, 'openspec', 'schemas', schemaName, 'schema.yaml'));
    return file.existsSync() ? file.path : '';
  }

  String get trackerFile => _existing(p.join(root.path, 'openspec',
      'redmine.yaml'));

  String get workspaceFile => _existing(p.join(root.path, 'workspace.yaml'));

  String get docDir {
    final dir = Directory(p.join(root.path, 'openspec', 'doc'));
    return dir.existsSync() ? dir.path : '';
  }

  static String _existing(String path) =>
      File(path).existsSync() ? path : '';

  // ─── Схема спеки ───────────────────────────────────────────────────────────

  SpecSchema? _schemaCache;

  /// Схема из `openspec/config.yaml` → `openspec/schemas/<name>/schema.yaml`.
  /// Её нет — вернётся пустая схема, работает эвристика по именам файлов.
  SpecSchema loadSchema() => _schemaCache ??= _readSchema();

  SpecSchema _readSchema() {
    final schemaName = _yamlValue(
        File(p.join(root.path, 'openspec', 'config.yaml')), ['schema']);
    if (schemaName == null) return SpecSchema.empty;
    final file = File(p.join(
        root.path, 'openspec', 'schemas', schemaName, 'schema.yaml'));
    if (!file.existsSync()) return SpecSchema.empty;
    final yaml = loadYaml(file.readAsStringSync());
    final artifacts = yaml['artifacts'];
    return SpecSchema(
      name: schemaName,
      artifacts: [
        if (artifacts is YamlList)
          for (final artifact in artifacts)
            SchemaArtifact(
              id: artifact['id'].toString(),
              generates: artifact['generates']?.toString() ?? '',
              description: artifact['description']?.toString() ?? '',
              requires: [
                if (artifact['requires'] is YamlList)
                  for (final required in artifact['requires'])
                    required.toString(),
              ],
            ),
      ],
      branchTemplate:
          _branchTemplate(yaml['apply']?['instruction']?.toString()),
    );
  }

  /// Имя ветки change'а объявлено в apply.instruction схемы:
  /// `git checkout -B features/<change-name>`.
  String _branchTemplate(String? applyInstruction) {
    if (applyInstruction == null) return 'features/<change>';
    final match = RegExp(r'checkout\s+-B\s+(\S*<change[^\s`]*>)')
        .firstMatch(applyInstruction);
    return match?.group(1) ?? 'features/<change>';
  }

  // ─── Статусы трекера ───────────────────────────────────────────────────────

  /// Семантика статусов из `openspec/redmine.yaml`: что значит «в работе»,
  /// «на ревью», «завершено» для этой спеки.
  StatusSemantics loadStatusSemantics() {
    final file = File(p.join(root.path, 'openspec', 'redmine.yaml'));
    if (!file.existsSync()) return StatusSemantics.empty;
    final yaml = loadYaml(file.readAsStringSync());
    final statuses = yaml['statuses'];
    final sync = yaml['sync'];
    return StatusSemantics(
      statuses: [
        if (statuses is YamlList)
          for (final status in statuses)
            TrackerStatus(
              id: int.tryParse('${status['id']}') ?? -1,
              name: status['name']?.toString() ?? '',
              closing: status['closing'] == true,
              completesTask: status['completes_task'] == true,
            ),
      ],
      sync: {
        if (sync is YamlMap)
          for (final entry in sync.entries)
            entry.key.toString(): ?int.tryParse('${entry.value}'),
      },
    );
  }

  /// Базовые значения трекера, которых нет в .env: project_id спеки.
  String? get trackerProjectId => _yamlValue(
      File(p.join(root.path, 'openspec', 'redmine.yaml')),
      ['defaults', 'project_id']);

  // ─── Группы ────────────────────────────────────────────────────────────────

  /// Группы change'ей: спринты (каталог со `sprint.yaml`), иначе мастер-спеки
  /// (`openspec/doc/*.md`), иначе плоский список.
  List<Group> loadGroups(List<ChangeUnit> changes) {
    final docDir = Directory(p.join(root.path, 'openspec', 'doc'));
    final groups = <Group>[];
    if (docDir.existsSync()) {
      final sprintDirs = docDir
          .listSync()
          .whereType<Directory>()
          .where((dir) => File(p.join(dir.path, 'sprint.yaml')).existsSync())
          .toList();
      if (sprintDirs.isNotEmpty) {
        groups.addAll(sprintDirs.map((dir) => _sprintGroup(dir, changes)));
      } else {
        final docs = docDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'))
            .toList();
        groups.addAll(docs.map((file) => _masterDocGroup(file, changes)));
      }
    }
    final grouped = {for (final group in groups) ...group.changeIds};
    final ungrouped = [
      for (final change in changes)
        if (!grouped.contains(change.id)) change.id,
    ];
    // Change'и вне групп не должны исчезать с экрана — им отдельная группа.
    if (ungrouped.isNotEmpty) {
      groups.add(Group(
        id: '',
        title: '',
        kind: GroupingKind.none,
        changeIds: ungrouped,
      ));
    }
    // Группа с работой идёт первой: она открывается по умолчанию, и пустая
    // мастер-спека не должна встречать человека пустым экраном.
    groups.sort((a, b) {
      final byFilled =
          (b.changeIds.isEmpty ? 0 : 1) - (a.changeIds.isEmpty ? 0 : 1);
      return byFilled != 0 ? byFilled : a.id.compareTo(b.id);
    });
    return groups;
  }

  Group _sprintGroup(Directory dir, List<ChangeUnit> changes) {
    final sprintId = p.basename(dir.path);
    final yaml = _yamlOf(File(p.join(dir.path, 'sprint.yaml')));
    final branches = yaml?['branches'];
    final docFile = File(p.join(dir.path, 'doc.md'));
    return Group(
      id: sprintId,
      title: _docTitle(docFile) ?? sprintId,
      kind: GroupingKind.sprintDir,
      branches: {
        if (branches is YamlMap)
          for (final entry in branches.entries)
            if (entry.value?['name'] != null)
              entry.key.toString(): entry.value['name'].toString(),
      },
      builds: _loadBuilds(dir),
      docPath: docFile.existsSync() ? docFile.path : null,
      delivery: yaml?['delivery']?.toString() ?? 'batch',
      changeIds: [
        for (final change in changes)
          if (change.groupId == sprintId) change.id,
      ],
    );
  }

  /// Мастер-спека `openspec/doc/<name>.md`: change'и перечислены в тексте
  /// документа (раздел «Набор OpenSpec changes») либо ссылаются на него сами.
  Group _masterDocGroup(File file, List<ChangeUnit> changes) {
    final docId = p.basenameWithoutExtension(file.path);
    final text = file.readAsStringSync();
    return Group(
      id: docId,
      title: _docTitle(file) ?? docId,
      kind: GroupingKind.masterDoc,
      docPath: file.path,
      changeIds: [
        for (final change in changes)
          if (change.groupId == docId || text.contains(change.id)) change.id,
      ],
    );
  }

  String? _docTitle(File docFile) {
    if (!docFile.existsSync()) return null;
    final lines = docFile.readAsLinesSync();
    final heading = lines.firstWhere((line) => line.startsWith('# '),
        orElse: () => lines.isEmpty ? '' : lines.first);
    final title = heading.startsWith('# ') ? heading.substring(2) : heading;
    if (title.trim().isEmpty) return null;
    // «pin-biometric-auth — Локальный вход: master-spec» → человеческая часть.
    final match = RegExp(r'^\s*\S+\s*[—–-]\s*(.+?)(:\s*master-spec)?\s*$')
        .firstMatch(title);
    return (match?.group(1) ?? title).trim();
  }

  Map<String, BuildInfo> _loadBuilds(Directory dir) {
    final yaml = _yamlOf(File(p.join(dir.path, 'builds.yaml')));
    if (yaml is! YamlMap) return const {};
    return {
      for (final entry in yaml.entries)
        entry.key.toString(): ?_buildOf(entry.key.toString(), entry.value),
    };
  }

  BuildInfo? _buildOf(String stack, dynamic node) {
    final builds = node is YamlMap ? node['builds'] : null;
    if (builds is! YamlList || builds.isEmpty) return null;
    final build = builds.first;
    final versionCode = build['version_code'];
    final versionName = versionCode == null
        ? build['version_name']?.toString()
        : '${build['version_name']}($versionCode)';
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

  /// Архивные change'и: `openspec/changes/archive/<YYYY-MM-DD>-<change>`.
  /// Дата берётся из имени каталога, а id — очищенным от неё: иначе
  /// связь с задачей трекера и группой рвётся.
  List<ChangeUnit> loadArchivedChanges() {
    final archiveDir =
        Directory(p.join(root.path, 'openspec', 'changes', 'archive'));
    if (!archiveDir.existsSync()) return [];
    final datePrefix = RegExp(r'^(\d{4}-\d{2}-\d{2})[-_](.+)$');
    final changes = [
      for (final entry in archiveDir.listSync().whereType<Directory>())
        () {
          final name = p.basename(entry.path);
          final match = datePrefix.firstMatch(name);
          final changeId = match?.group(2) ?? name;
          final archivedAt = DateTime.tryParse(match?.group(1) ?? '');
          final change = _loadChange(changeId, entry);
          return ChangeUnit(
            id: change.id,
            title: change.title,
            dir: change.dir,
            groupId: change.groupId,
            stackStates: change.stackStates,
            dependsOn: change.dependsOn,
            formatWarning: change.formatWarning,
            archivedAt: archivedAt,
          );
        }(),
    ];
    // Свежий архив сверху: без даты — в конец, туда же и одноимённые.
    changes.sort((a, b) =>
        (b.archivedAt ?? DateTime(0)).compareTo(a.archivedAt ?? DateTime(0)));
    return changes;
  }

  // ─── Документы ─────────────────────────────────────────────────────────────

  /// Дерево документов: группа → её change'и → файлы артефактов схемы.
  /// Мастер-спека, лежащая одним файлом, — это документ самой группы,
  /// у неё нет каталога. Архив идёт отдельным узлом в конце.
  List<DocNode> loadDocTree(List<Group> groups, List<ChangeUnit> changes,
      {List<ChangeUnit> archived = const []}) {
    final nodes = [
      for (final group in groups)
        DocNode(
          id: group.id,
          title: group.title,
          kind: DocNodeKind.group,
          branch: group.branches.values.firstOrNull ?? '',
          docs: [
            if (group.docPath case final path?)
              DocArtifact(
                p.basename(path),
                p.basename(path),
                path,
                File(path).existsSync(),
                id: group.kind == GroupingKind.masterDoc
                    ? DocArtifact.masterDocId
                    : DocArtifact.groupDocId,
              ),
          ],
          children: [
            for (final id in group.changeIds)
              ...changes
                  .where((change) => change.id == id)
                  .map((change) => _changeDocNode(change)),
          ],
        ),
    ];
    if (archived.isNotEmpty) {
      nodes.add(DocNode(
        id: archiveNodeId,
        title: '',
        kind: DocNodeKind.archivedChange,
        children: [for (final change in archived) _changeDocNode(change)],
      ));
    }
    return nodes;
  }

  /// Идентификатор узла архива — заголовок ему даёт слой представления.
  static const archiveNodeId = '::archive';

  DocNode _changeDocNode(ChangeUnit change) => DocNode(
        id: change.id,
        title: change.title,
        kind: change.archived ? DocNodeKind.archivedChange : DocNodeKind.change,
        branch: change.archived ? '' : loadSchema().branchFor(change.id),
        archivedAt: change.archivedAt,
        docs: _changeDocs(change),
      );

  /// Файлы change'а: одиночные артефакты схемы в объявленном ею порядке,
  /// плюс markdown, которого схема не знает, — он всё равно документ.
  /// У архивного change'а ненаписанных артефактов не показываем: работа
  /// сдана, и «чего в ней не хватает» — уже не вопрос.
  List<DocArtifact> _changeDocs(ChangeUnit change) {
    final schema = loadSchema();
    final declared = [
      for (final artifact in schema.artifacts)
        if (artifact.isSingleFile &&
            (!change.archived ||
                File(p.join(change.dir, artifact.generates)).existsSync()))
          DocArtifact(
            artifact.description.isEmpty ? artifact.id : artifact.description,
            artifact.generates,
            p.join(change.dir, artifact.generates),
            File(p.join(change.dir, artifact.generates)).existsSync(),
            id: artifact.id,
          ),
    ];
    final known = {for (final doc in declared) doc.fileName};
    final dir = Directory(change.dir);
    final extra = [
      for (final entry in dir.existsSync()
          ? dir.listSync().whereType<File>()
          : <File>[])
        if (entry.path.endsWith('.md') && !known.contains(p.basename(entry.path)))
          DocArtifact(p.basenameWithoutExtension(p.basename(entry.path)),
              p.basename(entry.path), entry.path, true),
    ]..sort((a, b) => a.fileName.compareTo(b.fileName));
    return [...declared, ...extra];
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
    final stackStates = <String, StackState>{};
    String? titleFromTasks;
    for (final (stack, file) in _taskFilesOf(changeDir)) {
      final (tasks, redmineTitle) = _loadTasksFile(file);
      if (tasks.isEmpty) continue;
      titleFromTasks ??= redmineTitle;
      final cached = links.stacks[_normalizedStack(stack, links.stacks.keys)];
      stackStates[stack] = StackState(
        stack: stack,
        issueId: cached?.issueId,
        tasks: tasks,
        cachedStatus: cached?.statusName,
      );
    }
    // Стеков нет — работа всё равно есть: один «стек работы» с задачей
    // change'а, иначе экран показал бы пустоту вместо статуса.
    if (stackStates.isEmpty && links.groupIssueId != null) {
      stackStates[StackState.singleWorkStack] = StackState(
        stack: StackState.singleWorkStack,
        issueId: links.groupIssueId,
        tasks: const [],
      );
    }

    return ChangeUnit(
      id: changeId,
      title: titleFromTasks ?? _proposalTitle(changeDir) ?? changeId,
      dir: changeDir.path,
      groupId: links.groupId,
      stackStates: stackStates,
      dependsOn:
          links.members.takeWhile((member) => member != changeId).toList(),
      formatWarning: links.formatWarning,
    );
  }

  /// Файлы задач change'а: имена берутся из схемы, иначе — по маске
  /// `tasks_*.md` (запасной путь для спек без схемы).
  List<(String, File)> _taskFilesOf(Directory changeDir) {
    final schema = loadSchema();
    if (!schema.isEmpty) {
      return [
        for (final stack in schema.stacks)
          if (schema.tasksFileFor(stack) case final fileName?)
            (stack, File(p.join(changeDir.path, fileName))),
      ];
    }
    final pattern = RegExp(r'^tasks[_-](.+)\.md$');
    return [
      for (final entry in changeDir.listSync().whereType<File>())
        if (pattern.firstMatch(p.basename(entry.path)) case final match?)
          (match.group(1)!, entry),
    ];
  }

  /// `tasks_ios` · `tasks-ios` · `tasksIos` · `ios` — один и тот же стек.
  String _normalizedStack(String stack, Iterable<String> candidates) {
    String flatten(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    return candidates.firstWhere(
        (candidate) => flatten(candidate) == flatten(stack),
        orElse: () => stack);
  }

  ({
    Map<String, ({int? issueId, String? statusName})> stacks,
    List<String> members,
    String groupId,
    int? groupIssueId,
    String formatWarning,
  }) _loadRedmineLinks(Directory changeDir) {
    final file = File(p.join(changeDir.path, 'redmine.yaml'));
    const empty = (
      stacks: <String, ({int? issueId, String? statusName})>{},
      members: <String>[],
      groupId: '',
      groupIssueId: null,
      formatWarning: '',
    );
    if (!file.existsSync()) return empty;
    final yaml = loadYaml(file.readAsStringSync());
    // Разбор идёт по версии формата: неизвестная версия — явная пометка,
    // а не молча пустое значение.
    final version = int.tryParse('${yaml['version']}');
    final supported = const [3, 4];
    final stacks = yaml['stacks'];
    final group = yaml['group'];
    final members = group?['members'];
    return (
      stacks: {
        if (stacks is YamlMap)
          for (final entry in stacks.entries)
            entry.key.toString(): (
              issueId: int.tryParse('${entry.value?['issue_id']}'),
              statusName: entry.value?['status_name']?.toString(),
            ),
      },
      members: members is YamlList
          ? members.map((member) => member.toString()).toList()
          : const <String>[],
      groupId: (group?['feature_sprint'] ?? group?['doc'])?.toString() ?? '',
      groupIssueId: int.tryParse('${group?['issue_id']}'),
      formatWarning: version == null || supported.contains(version)
          ? ''
          : '${p.basename(file.path)}: version $version',
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
    return EnvFile.parse(file.readAsStringSync());
  }

  /// Ключи из `.env.example` целиком, с подсказкой из комментария над строкой:
  /// белого списка нет — иначе ключи чужой спеки просто исчезнут с экрана.
  /// Закомментированные ключи (`# KEY=value`) тоже нужны — это опциональные.
  List<EnvKeyHint> loadEnvExampleKeys() {
    final file = File(p.join(root.path, '.env.example'));
    if (!file.existsSync()) return [];
    final keyPattern = RegExp(r'^#?\s*([A-Z0-9_]+)=');
    final keys = <String, EnvKeyHint>{};
    final comment = <String>[];
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      final match = keyPattern.firstMatch(line);
      if (match != null) {
        keys.putIfAbsent(
            match.group(1)!,
            () => (
                  key: match.group(1)!,
                  hint: _hintOf(comment),
                  optional: line.startsWith('#'),
                ));
        comment.clear();
        continue;
      }
      if (line.startsWith('#')) {
        comment.add(line.replaceFirst(RegExp(r'^#+\s*'), ''));
      } else if (line.isEmpty) {
        comment.clear();
      }
    }
    return keys.values.toList();
  }

  /// Подсказка — первая фраза комментария: разделители и многострочные
  /// инструкции в строку таблицы всё равно не помещаются.
  String _hintOf(List<String> comment) {
    final meaningful = comment
        .where((line) => RegExp(r'[A-Za-zА-Яа-я]').hasMatch(line))
        .map((line) => line.replaceAll(RegExp(r'[─—=]{2,}'), '').trim())
        .where((line) => line.isNotEmpty);
    final text = meaningful.join(' ');
    final sentenceEnd = text.indexOf(RegExp(r'[.:]\s'));
    final firstSentence = sentenceEnd < 0 ? text : text.substring(0, sentenceEnd);
    return firstSentence.length <= 120
        ? firstSentence
        : '${firstSentence.substring(0, 117)}…';
  }

  /// Скрипт подбора получателей передачи: спеки называют его по-разному,
  /// ищем по маске `scripts/*handover*recipient*`.
  String? get recipientsScript {
    final dir = Directory(p.join(root.path, 'scripts'));
    if (!dir.existsSync()) return null;
    final pattern = RegExp(r'handover.*recipient|recipient.*handover',
        caseSensitive: false);
    for (final entry in dir.listSync().whereType<File>()) {
      if (pattern.hasMatch(p.basename(entry.path))) {
        return p.relative(entry.path, from: root.path);
      }
    }
    return null;
  }

  /// Путь к `.env` спеки — он же показывается человеку перед записью.
  String get envPath => p.join(root.path, '.env');

  /// Пишет значения в `.env` спеки, сохраняя строки и комментарии, которых
  /// форма не касалась: файл нужен скриптам спеки и агентным сессиям.
  /// Пустое значение убирает ключ из файла — «ключ не заполнен», а не «=».
  Future<void> writeEnv(Map<String, String> values) async {
    final file = File(envPath);
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    final keyPattern = RegExp(r'^([A-Z0-9_]+)=');
    final written = <String>{};
    final result = <String>[];
    for (final line in lines) {
      final key = keyPattern.firstMatch(line.trim())?.group(1);
      if (key == null || !values.containsKey(key)) {
        result.add(line);
        continue;
      }
      written.add(key);
      final value = values[key]!;
      if (value.isNotEmpty) result.add('$key=$value');
    }
    for (final entry in values.entries) {
      if (!written.contains(entry.key) && entry.value.isNotEmpty) {
        result.add('${entry.key}=${entry.value}');
      }
    }
    // Пишем через временный файл: оборванная запись не оставит спеку
    // без ключей посреди рабочего дня.
    final temporary = File('$envPath.tmp');
    await temporary.writeAsString('${result.join('\n')}\n', flush: true);
    await temporary.rename(envPath);
  }

  /// Попадает ли `.env` под .gitignore спеки: секреты не должны уехать
  /// в репозиторий вместе с чужим коммитом.
  Future<bool> envIgnoredByGit() async {
    try {
      final result = await Process.run(
          ExecutableLocator.resolve('git'), ['-C', root.path, 'check-ignore', '-q', '.env']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Имя переменной роли: спека называет её по-своему (AVTOTO_ROLE и т.п.).
  String get roleKey =>
      loadEnv().keys.where((key) => key.endsWith('_ROLE')).firstOrNull ?? '';

  /// Роль машины из ключа `*_ROLE`.
  String get role => loadEnv()[roleKey] ?? '';

  /// Сервисы workspace.yaml, отфильтрованные по роли машины.
  List<({String name, String ref})> workspaceServices() => [
        for (final service in allServices())
          (name: service.name, ref: service.ref),
      ];

  /// Сервисы без фильтра по роли: для GitLab нужен репозиторий стека,
  /// даже если на этой машине он не склонирован.
  List<({String name, String ref, String repo, String stack})> allServices() {
    final file = File(p.join(root.path, 'workspace.yaml'));
    if (!file.existsSync()) return [];
    final services = loadYaml(file.readAsStringSync())['services'];
    if (services is! YamlList) return [];
    final machineRole = role;
    final stacks = loadSchema().stacks;
    return [
      for (final service in services)
        if (_serviceMatchesRole(service, machineRole))
          (
            name: service['name'].toString(),
            ref: service['ref'].toString(),
            repo: service['repo']?.toString() ?? '',
            stack: _stackOfService(service, stacks),
          ),
    ];
  }

  /// Стек сервиса из его ролей: «dev, ios» → ios. Ролей нет — стек пустой,
  /// и сервис считается общим для всей спеки.
  String _stackOfService(dynamic service, List<String> stacks) {
    final roles = (service['roles']?.toString() ?? '')
        .split(',')
        .map((role) => role.trim());
    for (final stack in stacks) {
      if (roles.contains(stack)) return stack;
    }
    return '';
  }

  bool _serviceMatchesRole(dynamic service, String machineRole) {
    if (machineRole.isEmpty) return true;
    final roles = service['roles'];
    if (roles == null) return true;
    return roles
        .toString()
        .split(',')
        .map((role) => role.trim())
        .contains(machineRole);
  }

  // ─── Команды платформы ─────────────────────────────────────────────────────

  /// Команды спеки из всех источников по приоритету: схема (канон) →
  /// `.claude/commands` → зеркала для других агентов → скрипты сборки.
  /// Дедуп по basename: в зеркалах лежат копии тех же файлов.
  List<SlashCommand> loadSlashCommands() {
    final byName = <String, SlashCommand>{};
    for (final (dir, source) in _commandDirs()) {
      for (final file in _markdownFiles(dir)) {
        final command = _loadSlashCommand(file, source);
        if (command == null) continue;
        byName.putIfAbsent(_commandKey(file), () => command);
      }
    }
    final commands = byName.values.toList();
    commands.sort((a, b) => a.id.compareTo(b.id));
    // Скрипты сборки — тоже команды спеки: у avelacom там opsx:new,
    // openspec:redmine и workspace-init. Имена с командами не пересекаются.
    return [...commands, ..._packageScripts(), ..._makeTargets()];
  }

  /// Ключ дедупа: имя файла, а у навыков — имя каталога, иначе все
  /// `SKILL.md` схлопнулись бы в одну команду.
  String _commandKey(File file) {
    final name = p.basenameWithoutExtension(file.path);
    return name.toUpperCase() == 'SKILL'
        ? p.basename(file.parent.path)
        : name;
  }

  List<(Directory, CommandSource)> _commandDirs() {
    final schemaName = loadSchema().name;
    final candidates = <(String, CommandSource)>[
      if (schemaName.isNotEmpty)
        (
          p.join(root.path, 'openspec', 'schemas', schemaName, 'commands'),
          CommandSource.schema
        ),
      (p.join(root.path, '.claude', 'commands'), CommandSource.claude),
      (p.join(root.path, '.claude', 'skills'), CommandSource.claude),
      for (final mirror in const ['.codex', '.cursor', '.kilocode', '.windsurf'])
        ...[
          (p.join(root.path, mirror, 'commands'), CommandSource.mirror),
          (p.join(root.path, mirror, 'prompts'), CommandSource.mirror),
        ],
    ];
    return [
      for (final (dir, source) in candidates)
        if (Directory(dir).existsSync()) (Directory(dir), source),
    ];
  }

  /// Скрипты `package.json` — вызываются как есть, сигнатуры не имеют.
  List<SlashCommand> _packageScripts() {
    final file = File(p.join(root.path, 'package.json'));
    if (!file.existsSync()) return const [];
    final scripts = <SlashCommand>[];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      final block = decoded is Map ? decoded['scripts'] : null;
      if (block is! Map) return const [];
      final runner = (File(p.join(root.path, 'pnpm-lock.yaml')).existsSync() ||
              File(p.join(root.path, 'pnpm-workspace.yaml')).existsSync())
          ? 'pnpm'
          : 'npm run';
      for (final entry in block.entries) {
        scripts.add(SlashCommand(
          id: entry.key.toString(),
          description: entry.value.toString(),
          source: CommandSource.packageScript,
          runLine: '$runner ${entry.key}',
        ));
      }
    } on FormatException {
      // Битый package.json — не повод терять остальные команды спеки.
      return const [];
    }
    scripts.sort((a, b) => a.id.compareTo(b.id));
    return scripts;
  }

  /// Цели `Makefile` — берём только объявленные, без служебных и шаблонов.
  List<SlashCommand> _makeTargets() {
    final file = File(p.join(root.path, 'Makefile'));
    if (!file.existsSync()) return const [];
    final targetPattern = RegExp(r'^([a-zA-Z][\w.-]*)\s*:(?!=)');
    final targets = <SlashCommand>[];
    String? comment;
    for (final line in file.readAsLinesSync()) {
      if (line.startsWith('#')) {
        comment = line.substring(1).trim();
        continue;
      }
      final match = targetPattern.firstMatch(line);
      if (match == null) {
        comment = null;
        continue;
      }
      final name = match.group(1)!;
      if (name == '.PHONY') continue;
      targets.add(SlashCommand(
        id: name,
        description: comment ?? '',
        source: CommandSource.makeTarget,
        runLine: 'make $name',
      ));
      comment = null;
    }
    return targets;
  }

  Iterable<File> _markdownFiles(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'));

  SlashCommand? _loadSlashCommand(File file, CommandSource source) {
    final lines = file.readAsLinesSync();
    final frontmatter = <String, String>{};
    var insideFrontmatter = false;
    var frontmatterEnd = 0;
    final fieldPattern = RegExp(r'^([a-z-]+):\s*(.*)$');
    for (final (index, line) in lines.indexed) {
      if (line.trim() == '---') {
        if (insideFrontmatter) {
          frontmatterEnd = index;
          break;
        }
        insideFrontmatter = true;
        continue;
      }
      if (!insideFrontmatter) continue;
      final match = fieldPattern.firstMatch(line);
      if (match != null) {
        frontmatter[match.group(1)!] = match.group(2)!.trim().replaceAll('"', '');
      }
    }
    // Имя команды пишет сама спека: файл opsx-apply.md, а зовётся она
    // /opsx:apply — нормализовать разделитель за спеку нельзя.
    final id = (frontmatter['name'] ?? frontmatter['id'] ??
            p.basenameWithoutExtension(file.path))
        .replaceFirst(RegExp(r'^/'), '');
    final description = frontmatter['description'] ?? '';
    if (description.isEmpty) return null;
    return SlashCommand(
      id: id,
      description: description,
      source: source,
      argumentHint: frontmatter['argument-hint'] ??
          _argumentHintFromBody(lines.skip(frontmatterEnd)),
    );
  }

  /// Спеки без `argument-hint` описывают аргументы разделом «**Input**»:
  /// строкой вызова `/opsx:apply <change> [<change>...]` либо прозой.
  /// Разбираем её в те же слоты, что и подсказка терминала.
  String _argumentHintFromBody(Iterable<String> body) {
    const slots = ['change', 'sprint', 'group', 'doc'];
    final lines = body.toList();
    final start =
        lines.indexWhere((line) => line.trimLeft().startsWith('**Input**'));
    if (start < 0) return '';
    final section = lines.skip(start).take(12).toList();
    final usage = section
        .where((line) => line.trimLeft().startsWith('/'))
        .firstOrNull;
    if (usage != null) {
      return [
        for (final slot in slots)
          if (usage.contains('<$slot') || usage.contains('[$slot')) '[$slot]',
      ].join(' ');
    }
    // Сигнатуры нет — берём упоминание сущности из текста раздела.
    final prose = section.join(' ').toLowerCase();
    return [
      for (final slot in slots)
        if (prose.contains(slot)) '[$slot]',
    ].take(1).join();
  }

  // ─── Git ───────────────────────────────────────────────────────────────────

  /// Подтягивает свежие изменения спеки перед чтением: спеки и чеклисты
  /// правят коллеги, без pull кнопка «Обновить» показывала бы вчерашнее.
  /// Только fast-forward; любая ошибка (офлайн, локальные правки) не мешает
  /// работе с тем, что есть на диске.
  Future<void> pullPlatform() async {
    final run = commandLog?.begin('git -C ${root.path} pull --ff-only');
    try {
      final result =
          await Process.run(ExecutableLocator.resolve('git'), ['-C', root.path, 'pull', '--ff-only'])
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

  /// Ветка спеки и состояние файла документа в ней: документы правит
  /// и агент, и человек, поэтому «что именно я читаю» — часть экрана.
  Future<DocState> docState(String absolutePath) async {
    final branch = await _git(root.path, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch == null) return DocState.unknown;
    final relative = p.relative(absolutePath, from: root.path);
    final status = await _git(root.path, ['status', '--porcelain', '--', relative]);
    if (status == null) {
      return DocState(branch: branch, file: DocFileState.unknown);
    }
    return DocState(
      branch: branch,
      file: switch (status.trim()) {
        '' => DocFileState.clean,
        final line when line.startsWith('??') => DocFileState.untracked,
        _ => DocFileState.modified,
      },
    );
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
      final result = await Process.run(ExecutableLocator.resolve('git'), ['-C', repoDir, ...args]);
      if (result.exitCode != 0) return null;
      return (result.stdout as String).trim();
    } catch (_) {
      return null;
    }
  }

  // ─── Вспомогательное ───────────────────────────────────────────────────────

  dynamic _yamlOf(File file) =>
      file.existsSync() ? loadYaml(file.readAsStringSync()) : null;

  String? _yamlValue(File file, List<String> keyPath) {
    dynamic node = _yamlOf(file);
    for (final key in keyPath) {
      node = node?[key];
    }
    return node?.toString();
  }
}
