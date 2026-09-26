import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

/// Артефакт схемы спеки: что за файл, чем порождается, от чего зависит.
class SchemaArtifact {
  final String id;
  final String generates; // proposal.md | tasks_backend.md | specs/**/*.md
  final String description;
  final List<String> requires;

  const SchemaArtifact({
    required this.id,
    required this.generates,
    this.description = '',
    this.requires = const [],
  });

  /// Стек артефакта задач: `tasks-backend` → backend, иначе пусто.
  String get stack => id.startsWith('tasks-') ? id.substring(6) : '';

  /// Файл артефакта одиночный (можно открыть), а не маска каталога.
  bool get isSingleFile => !generates.contains('*');

  /// Артефакт — дельты спецификаций. Правило upstream: решает префикс пути
  /// `specs/`, а не id, — его наследуют и кастомные схемы.
  bool get isSpecsDelta =>
      generates.startsWith('specs/') || generates.startsWith('specs\\');

  /// Файлы артефакта в каталоге change'а. Одиночный — сам файл, если он
  /// есть; маска — все подходящие файлы (`specs/**/*.md`).
  List<String> filesIn(String changeDir) {
    if (isSingleFile) {
      final path = p.join(changeDir, generates);
      return File(path).existsSync() ? [path] : const [];
    }
    if (!Directory(changeDir).existsSync()) return const [];
    final matches = Glob(generates).listSync(root: changeDir).whereType<File>();
    return [for (final file in matches) file.path]..sort();
  }

  /// Артефакт написан: одиночный файл есть, у маски — хотя бы один файл.
  bool existsIn(String changeDir) => filesIn(changeDir).isNotEmpty;
}

/// Схема спеки — `openspec/schemas/<name>/schema.yaml` проекта, схема
/// пользователя или встроенная копия схемы upstream.
/// Источник правды об именах файлов, стеках и порядке артефактов.
/// Пустая схема (`SpecSchema.empty`) — схема не найдена; работает эвристика
/// по именам файлов.
class SpecSchema {
  final String name;
  final List<SchemaArtifact> artifacts;

  /// Имя ветки change'а из `apply.instruction`; null — спека веток не
  /// объявляет, и приложение их не выдумывает.
  final String? branchTemplate;

  /// Файл с чекбоксами задач из `apply.tracks`; null — схема его не
  /// объявляет.
  final String? tracksFile;

  const SpecSchema({
    required this.name,
    required this.artifacts,
    this.branchTemplate,
    this.tracksFile,
  });

  static const empty = SpecSchema(name: '', artifacts: []);

  bool get isEmpty => artifacts.isEmpty;

  /// Стеки схемы = артефакты вида `tasks-<stack>`, а не любые ключи
  /// `stacks:` в redmine.yaml (иначе root и manager дают фантомные стеки).
  List<String> get stacks =>
      [for (final artifact in artifacts) artifact.stack]
          .where((stack) => stack.isNotEmpty)
          .toList();

  /// Имя файла задач стека: backend → `tasks_backend.md`.
  String? tasksFileFor(String stack) => artifacts
      .where((artifact) => artifact.stack == stack)
      .map((artifact) => artifact.generates)
      .firstOrNull;

  /// Единственный файл задач change'а без стеков: `apply.tracks`, иначе
  /// артефакт с id `tasks` (так устроена схема upstream).
  String? get singleTasksFile =>
      tracksFile ??
      artifacts
          .where((artifact) => artifact.id == 'tasks')
          .map((artifact) => artifact.generates)
          .firstOrNull;

  /// Артефакт спеки изменения: `proposal` схемы, иначе `proposal.md`.
  SchemaArtifact? get specArtifact =>
      artifacts.where((artifact) => artifact.id == 'proposal').firstOrNull ??
      artifacts
          .where((artifact) => artifact.generates == 'proposal.md')
          .firstOrNull;

  /// Путь к спеке изменения внутри его каталога; null — схема её не знает.
  String? specPathFor(String changeDir) {
    final generates = specArtifact?.generates ?? 'proposal.md';
    if (generates.contains('*')) return null;
    return '$changeDir/$generates';
  }

  /// Ветка change'а по шаблону схемы; null — ветка не объявлена.
  String? branchFor(String changeId) => branchTemplate
      ?.replaceAll('<change>', changeId)
      .replaceAll('<change-name>', changeId);
}
