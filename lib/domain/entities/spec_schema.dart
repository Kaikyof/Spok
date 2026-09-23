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
}

/// Схема спеки — `openspec/schemas/<name>/schema.yaml`.
/// Источник правды об именах файлов, стеках и порядке артефактов.
/// Пустая схема (`SpecSchema.empty`) — работает эвристика по именам файлов.
class SpecSchema {
  final String name;
  final List<SchemaArtifact> artifacts;

  /// Имя ветки change'а из `apply.instruction`; по умолчанию `features/<change>`.
  final String branchTemplate;

  const SpecSchema({
    required this.name,
    required this.artifacts,
    this.branchTemplate = 'features/<change>',
  });

  static const empty = SpecSchema(name: '', artifacts: []);

  bool get isEmpty => artifacts.isEmpty;

  /// Стеки схемы = артефакты вида `tasks-<stack>`, а не любые ключи
  /// `stacks:` в redmine.yaml (иначе root и manager дают фантомные стеки).
  List<String> get stacks =>
      [for (final artifact in artifacts) artifact.stack].where((stack) => stack.isNotEmpty).toList();

  /// Имя файла задач стека: backend → `tasks_backend.md`.
  String? tasksFileFor(String stack) => artifacts
      .where((artifact) => artifact.stack == stack)
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

  String branchFor(String changeId) =>
      branchTemplate.replaceAll('<change>', changeId).replaceAll('<change-name>', changeId);
}
