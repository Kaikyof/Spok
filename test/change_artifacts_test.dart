import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/usecases/list_change_artifacts.dart';

/// Метаданные `.openspec.yaml`, артефакты-маски, пропуск спецификаций,
/// заголовок и ветка. Сценарии — из спецификации `change-artifacts`.
void main() {
  late Directory root;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('change-artifacts');
    write('openspec/config.yaml', 'schema: spec-driven\n');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('дельта спецификации написана: «2 из 4», design и tasks ждут', () {
    write('openspec/changes/a/proposal.md', '## Why\n');
    write('openspec/changes/a/specs/auth/spec.md', '## ADDED Requirements\n');
    final change = PlatformFilesSource(root).loadChanges().single;
    final states = const ListChangeArtifacts()(change, change.schema);

    expect(states.map((state) => state.artifact.id), [
      'proposal',
      'specs',
      'design',
      'tasks',
    ]);
    expect(ListChangeArtifacts.progress(states), (done: 2, total: 4));
    final byId = {for (final state in states) state.artifact.id: state};
    expect(byId['specs']!.files.single, endsWith('specs/auth/spec.md'));
    expect(byId['design']!.waitingFor, isEmpty);
    expect(byId['tasks']!.waitingFor, ['design']);
  });

  test('пропуск спецификаций: артефакт пропущен, а не ненаписан', () {
    write('openspec/changes/a/.openspec.yaml', 'skip_specs: true\n');
    write('openspec/changes/a/proposal.md', '## Why\n');
    write('openspec/changes/a/design.md', '## Context\n');
    final change = PlatformFilesSource(root).loadChanges().single;
    expect(change.meta.skipSpecs, isTrue);

    final states = const ListChangeArtifacts()(change, change.schema);
    final byId = {for (final state in states) state.artifact.id: state};
    expect(byId['specs']!.skipped, isTrue);
    expect(byId['specs']!.exists, isFalse);
    // tasks требует specs и design: specs пропущен, design написан — не ждёт.
    expect(byId['tasks']!.waitingFor, isEmpty);
    expect(ListChangeArtifacts.progress(states), (done: 2, total: 3));
  });

  test('метаданные .openspec.yaml читаются целиком', () {
    write('openspec/changes/a/.openspec.yaml', '''
schema: spec-driven
created: 2026-09-20
goal: Убрать дубли
''');
    write('openspec/changes/a/proposal.md', '## Why\n');
    final meta = PlatformFilesSource(root).loadChanges().single.meta;
    expect(meta.schemaName, 'spec-driven');
    expect(meta.created, DateTime(2026, 9, 20));
    expect(meta.goal, 'Убрать дубли');
    expect(meta.skipSpecs, isFalse);
  });

  test('кривой .openspec.yaml — метаданных нет, без падения', () {
    write('openspec/changes/a/.openspec.yaml', '- список\n');
    write('openspec/changes/a/proposal.md', '## Why\n');
    final change = PlatformFilesSource(root).loadChanges().single;
    expect(change.meta.schemaName, isNull);
  });

  group('заголовок', () {
    test('шаблон upstream без H1 — id', () {
      write('openspec/changes/add-dark-mode/proposal.md', '## Why\n\nText\n');
      expect(
        PlatformFilesSource(root).loadChanges().single.title,
        'add-dark-mode',
      );
    });

    test('H1 с префиксом Proposal: — префикс снят', () {
      write(
        'openspec/changes/a/proposal.md',
        '# Proposal: Тёмная тема\n\n## Why\n',
      );
      expect(
        PlatformFilesSource(root).loadChanges().single.title,
        'Тёмная тема',
      );
    });

    test('обычный H1 — как прежде', () {
      write('openspec/changes/a/proposal.md', '# Альфа\n');
      expect(PlatformFilesSource(root).loadChanges().single.title, 'Альфа');
    });
  });

  group('ветка', () {
    test(
      'схема spec-driven — ветки нет, дерево документов её не показывает',
      () {
        write('openspec/changes/a/proposal.md', '## Why\n');
        final source = PlatformFilesSource(root);
        final change = source.loadChanges().single;
        expect(change.schema.branchFor(change.id), isNull);
        final tree = source.loadDocTree(source.loadGroups([change]), [change]);
        expect(tree.single.children.single.branch, isEmpty);
      },
    );

    test('схема с checkout -B в apply.instruction — ветка из шаблона', () {
      write('openspec/config.yaml', 'schema: branchy\n');
      write('openspec/schemas/branchy/schema.yaml', '''
name: branchy
artifacts:
  - id: proposal
    generates: proposal.md
apply:
  instruction: |
    3. Branches: `git fetch && git checkout -B features/<change-name>`
''');
      write('openspec/changes/a/proposal.md', '# A\n');
      final change = PlatformFilesSource(root).loadChanges().single;
      expect(change.schema.branchFor('a'), 'features/a');
    });
  });
}
