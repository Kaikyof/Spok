import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/data/sources/schema_resolver.dart';
import 'package:spok/domain/entities/stack_state.dart';

import 'upstream_fixture.dart';

/// Поведение на проекте оригинального OpenSpec по мере этапов плана.
///
/// После этапа 1 (`resolve-schema-like-upstream`) схема берётся из
/// встроенной копии, задачи — из `tasks.md`, единица работы есть без
/// трекера. Что ещё не сделано (команды — этап 3), здесь зафиксировано как
/// есть, чтобы следующий этап ломал этот тест осознанно.
void main() {
  late Directory root;
  late PlatformFilesSource source;

  setUp(() {
    root = buildUpstreamSpec();
    source = PlatformFilesSource(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('корень распознаётся: достаточно каталога openspec/', () {
    expect(PlatformFilesSource.isPlatformRoot(root.path), isTrue);
  });

  test('схема — встроенная spec-driven: в проекте её нет, файла для '
      '«изменить» тоже', () {
    expect(source.loadSchema().name, 'spec-driven');
    expect(source.defaultSchemaResolution?.source, SchemaSource.builtin);
    expect(source.schemaFile, isEmpty);
    expect(source.loadSchema().stacks, isEmpty);
  });

  test('change\'и с задачами из tasks.md, единица работы без трекера', () {
    final changes = source.loadChanges();
    final byId = {for (final change in changes) change.id: change};
    expect(byId.keys, containsAll(['add-dark-mode', 'refactor-config']));
    expect(changes.length, 2);

    final darkMode = byId['add-dark-mode']!.stack(StackState.singleWorkStack)!;
    // `* [X] 1.1`, `* [ ] 1.2`, `  - [ ] 1.3`, `- [~] …` — четыре задачи,
    // одна закрыта; ссылка `- [Design notes](./design.md)` не задача.
    expect(darkMode.tasks.length, 4);
    expect(darkMode.doneCount, 1);
    expect(darkMode.issueId, isNull);
    expect(darkMode.redmineStatus, isNull);

    expect(byId['refactor-config']!.meta.skipSpecs, isTrue);
    expect(byId['refactor-config']!.stacks.single.tasks.length, 1);

    for (final change in changes) {
      // Заголовка первого уровня в proposal.md upstream нет — id.
      expect(change.title, change.id);
      expect(change.schema.name, 'spec-driven');
      expect(change.schema.branchFor(change.id), isNull);
    }
  });

  test('архив с датой в имени читается, id очищен', () {
    final archived = source.loadArchivedChanges();
    expect(archived.single.id, 'add-login');
    expect(archived.single.archivedAt, DateTime(2026, 9, 1));
    expect(archived.single.stacks.single.doneCount, 1);
  });

  test('команды: имя из frontmatter принимается за вызов, скилл — дубль', () {
    final ids = source.loadSlashCommands().map((command) => command.id);
    // Это ошибка, которую чинит `support-upstream-commands`: Claude Code
    // регистрирует `/opsx:propose` по пути файла, а не по `name`.
    expect(
      ids,
      containsAll(['OPSX: Propose', 'OPSX: Apply', 'openspec-propose']),
    );
  });

  test('окружение: ключей и сервисов нет', () {
    expect(source.loadEnvExampleKeys(), isEmpty);
    expect(source.allServices(), isEmpty);
    expect(source.loadStatusSemantics().isEmpty, isTrue);
  });
}
