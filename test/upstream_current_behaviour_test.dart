import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/sources/platform_files_source.dart';

import 'upstream_fixture.dart';

/// Сегодняшнее поведение на проекте оригинального OpenSpec — зафиксировано,
/// чтобы следующие этапы (`resolve-schema-like-upstream` и дальше) ломали
/// этот тест осознанно и переписывали его, а не обнаруживали регрессию
/// случайно. Каждое `expect` здесь — строка из раздела 2
/// `docs/openspec-upstream-plan.md`.
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

  test('схема пустая: в проекте нет openspec/schemas, а пакет upstream '
      'приложение не читает', () {
    expect(source.loadSchema().isEmpty, isTrue);
    expect(source.schemaFile, isEmpty);
  });

  test('change\'и находятся, но без стеков и без задач', () {
    final changes = source.loadChanges();
    expect(
      changes.map((change) => change.id),
      containsAll(['add-dark-mode', 'refactor-config']),
    );
    expect(changes.length, 2);
    for (final change in changes) {
      expect(change.stacks, isEmpty, reason: '${change.id}: стеков нет');
      // Заголовка первого уровня в proposal.md upstream нет — id.
      expect(change.title, change.id);
    }
  });

  test('архив с датой в имени читается, id очищен', () {
    final archived = source.loadArchivedChanges();
    expect(archived.single.id, 'add-login');
    expect(archived.single.archivedAt, DateTime(2026, 9, 1));
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
