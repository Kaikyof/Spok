import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/builtin_schemas.dart';
import 'package:spok/data/sources/schema_resolver.dart';
import 'package:spok/data/sources/platform_files_source.dart';

const _rapidSchema = '''
name: rapid
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []
  - id: tasks
    generates: tasks.md
    requires: [proposal]
apply:
  requires: [tasks]
  tracks: tasks.md
''';

/// Схема ищется там же и в том же порядке, что у upstream: проект →
/// пользователь → встроенная копия. Сценарии — из спецификации
/// `schema-resolution` change'а `resolve-schema-like-upstream`.
void main() {
  late Directory root;
  late Directory userDir;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('schema-resolver');
    userDir = Directory.systemTemp.createTempSync('schema-user');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    userDir.deleteSync(recursive: true);
  });

  group('SchemaResolver', () {
    test('проект после openspec init — встроенная копия', () {
      final resolved = SchemaResolver(
        root,
        userSchemasDir: userDir,
      ).resolve(defaultSchemaName);
      expect(resolved?.source, SchemaSource.builtin);
      expect(resolved?.path, isEmpty);
      expect(resolved?.schema.tracksFile, 'tasks.md');
    });

    test('схема команды в проекте — источник project', () {
      write('openspec/schemas/spec-driven/schema.yaml', _rapidSchema);
      final resolved = SchemaResolver(
        root,
        userSchemasDir: userDir,
      ).resolve('spec-driven');
      expect(resolved?.source, SchemaSource.project);
      expect(resolved?.path, endsWith('schema.yaml'));
      // Проектная схема побеждает встроенную с тем же именем.
      expect(resolved?.schema.artifacts.length, 2);
    });

    test('схема пользователя — ~/.local/share/openspec/schemas', () {
      final file = File(p.join(userDir.path, 'rapid', 'schema.yaml'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(_rapidSchema);
      final resolved = SchemaResolver(
        root,
        userSchemasDir: userDir,
      ).resolve('rapid');
      expect(resolved?.source, SchemaSource.user);
      expect(resolved?.path, file.path);
    });

    test('схема не найдена нигде — null, без исключений', () {
      final resolver = SchemaResolver(root, userSchemasDir: userDir);
      expect(resolver.resolve('nowhere'), isNull);
      expect(resolver.resolve(''), isNull);
    });

    test('кривой schema.yaml — схема без артефактов, не падение', () {
      expect(
        SchemaResolver.parse('odd', '- just\n- a list\n').artifacts,
        isEmpty,
      );
      expect(
        SchemaResolver.parse(
          'odd',
          'artifacts: [1, 2]\napply: text\n',
        ).artifacts,
        isEmpty,
      );
    });
  });

  group('шаблон ветки из apply.instruction', () {
    test('avelacom: git checkout -B features/<change-name>', () {
      expect(
        SchemaResolver.branchTemplateOf(
          '3. Branches: `git fetch && git checkout -B features/<change-name>`',
        ),
        'features/<change-name>',
      );
    });

    test('avtoto: заголовок шага **Branches `features/<change-name>`**', () {
      const instruction = '''
    2. **Redmine → В работе** (agent runs):
       `pnpm openspec:redmine set-status --change <name> --stack <stack>`

    3. **Branches `features/<change-name>`**:
       - avtoto-platform: create from current `origin/main`;
''';
      expect(
        SchemaResolver.branchTemplateOf(instruction),
        'features/<change-name>',
      );
    });

    test('ветка не объявлена — null, --change <name> не сбивает', () {
      expect(
        SchemaResolver.branchTemplateOf(
          'Run `openspec instructions apply --change <name> --json`.',
        ),
        isNull,
      );
      expect(SchemaResolver.branchTemplateOf(null), isNull);
    });
  });

  group('цепочка change → конфиг → умолчание', () {
    test('конфига нет — spec-driven', () {
      write('openspec/changes/a/proposal.md', '## Why\n');
      final source = PlatformFilesSource(root);
      expect(source.configuredSchemaName, isNull);
      expect(source.loadSchema().name, 'spec-driven');
      expect(source.defaultSchemaResolution?.source, SchemaSource.builtin);
      expect(source.loadChanges().single.schema.name, 'spec-driven');
    });

    test('схема из метаданных change\'а перекрывает конфиг', () {
      write('openspec/config.yaml', 'schema: spec-driven\n');
      write('openspec/schemas/rapid/schema.yaml', _rapidSchema);
      write('openspec/changes/a/.openspec.yaml', 'schema: rapid\n');
      write('openspec/changes/a/proposal.md', '## Why\n');
      write('openspec/changes/b/proposal.md', '## Why\n');
      final changes = PlatformFilesSource(root).loadChanges();
      final byId = {for (final change in changes) change.id: change};
      expect(byId['a']!.schema.name, 'rapid');
      expect(byId['a']!.meta.schemaName, 'rapid');
      expect(byId['b']!.schema.name, 'spec-driven');
    });

    test('конфиг назвал схему, которой нет: спека без схемы, change — на '
        'встроенной', () {
      write('openspec/config.yaml', 'schema: missing\n');
      write('openspec/changes/a/tasks.md', '- [ ] 1.1 Одна\n');
      final source = PlatformFilesSource(root);
      expect(source.defaultSchemaResolution, isNull);
      expect(source.loadSchema().isEmpty, isTrue);
      expect(source.schemaFile, isEmpty);
      final change = source.loadChanges().single;
      expect(change.schema.name, 'spec-driven');
      expect(change.stacks.single.tasks.length, 1);
    });
  });
}
