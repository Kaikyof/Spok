import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../domain/entities/spec_schema.dart';
import 'builtin_schemas.dart';

/// Откуда взята схема — показывается на экране распознавания.
enum SchemaSource { project, user, builtin }

/// Схема с источником и путём к файлу (пусто у встроенной).
class ResolvedSchema {
  final SpecSchema schema;
  final SchemaSource source;
  final String path;

  const ResolvedSchema({
    required this.schema,
    required this.source,
    this.path = '',
  });
}

/// Ищет схему по имени там же и в том же порядке, что upstream:
/// `openspec/schemas/<name>/` проекта → `~/.local/share/openspec/schemas/<name>/`
/// пользователя → встроенная копия из пакета upstream.
///
/// Копия нужна потому, что у проекта после `openspec init` схема лежит в
/// npm-пакете, а не в проекте, — и без неё Spok не знал бы даже, что
/// задачи живут в `tasks.md`. Когда появится источник из CLI
/// (`openspec schema which`), он встанет перед встроенной копией.
class SchemaResolver {
  final Directory root;
  final Directory? userSchemasDir;
  final Map<String, String> builtin;

  final _cache = <String, ResolvedSchema?>{};

  SchemaResolver(
    this.root, {
    Directory? userSchemasDir,
    this.builtin = builtinSchemas,
  }) : userSchemasDir = userSchemasDir ?? _defaultUserSchemasDir();

  /// `~/.local/share/openspec/schemas` — путь upstream для схем пользователя.
  static Directory? _defaultUserSchemasDir() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;
    return Directory(p.join(home, '.local', 'share', 'openspec', 'schemas'));
  }

  /// Схема по имени; null — не найдена нигде. Результат кэшируется на
  /// время жизни источника: у спеки обычно одна схема на все change'и.
  ResolvedSchema? resolve(String name) =>
      _cache.putIfAbsent(name, () => _lookup(name));

  ResolvedSchema? _lookup(String name) {
    if (name.isEmpty) return null;
    final project = File(
      p.join(root.path, 'openspec', 'schemas', name, 'schema.yaml'),
    );
    if (project.existsSync()) {
      return ResolvedSchema(
        schema: parse(name, project.readAsStringSync()),
        source: SchemaSource.project,
        path: project.path,
      );
    }
    final userDir = userSchemasDir;
    if (userDir != null) {
      final user = File(p.join(userDir.path, name, 'schema.yaml'));
      if (user.existsSync()) {
        return ResolvedSchema(
          schema: parse(name, user.readAsStringSync()),
          source: SchemaSource.user,
          path: user.path,
        );
      }
    }
    final text = builtin[name];
    if (text != null) {
      return ResolvedSchema(
        schema: parse(name, text),
        source: SchemaSource.builtin,
      );
    }
    return null;
  }

  /// Разбор `schema.yaml`. Неожиданная форма (не словарь, не список) даёт
  /// схему без артефактов, а не исключение: спека может быть устроена
  /// иначе, и это состояние «не распознано», а не падение.
  static SpecSchema parse(String name, String text) {
    final yaml = loadYaml(text);
    if (yaml is! YamlMap) return SpecSchema(name: name, artifacts: const []);
    final artifacts = yaml['artifacts'];
    final apply = yaml['apply'];
    return SpecSchema(
      name: name,
      artifacts: [
        if (artifacts is YamlList)
          for (final artifact in artifacts)
            if (artifact is YamlMap && artifact['id'] != null)
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
      branchTemplate: apply is YamlMap
          ? branchTemplateOf(apply['instruction']?.toString())
          : null,
      tracksFile: apply is YamlMap ? apply['tracks']?.toString() : null,
    );
  }

  /// Имя ветки change'а, если схема его объявила в apply.instruction.
  /// Форма у спек разная: у avelacom `git checkout -B features/<change-name>`,
  /// у avtoto заголовок шага ``**Branches `features/<change-name>`**``.
  /// Общее у них — путь со слешем и `<change…>` внутри; его и ищем.
  /// Не объявила — null: ветку за спеку не выдумываем.
  static String? branchTemplateOf(String? applyInstruction) {
    if (applyInstruction == null) return null;
    final template = RegExp(
      r"""(?:^|[\s`"'(])([\w.\-]+/[\w.\-/]*<change[^\s`>]*>[\w.\-/]*)""",
    );
    return template.firstMatch(applyInstruction)?.group(1);
  }
}
