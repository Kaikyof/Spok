import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/doc_artifact.dart';
import 'package:spok/domain/entities/doc_node.dart';

import 'upstream_fixture.dart';

/// Спецификации проекта и дельты change'ей в дереве документов
/// (change `show-specs-in-docs`).
void main() {
  late Directory root;
  late PlatformFilesSource source;

  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  List<DocNode> tree() {
    final changes = source.loadChanges();
    return source.loadDocTree(source.loadGroups(changes), changes, archived: source.loadArchivedChanges());
  }

  DocNode? specsNode() => tree().where((node) => node.id == PlatformFilesSource.specsNodeId).firstOrNull;

  DocNode changeNode(String id) =>
      tree().expand((node) => node.children).firstWhere((node) => node.id == id && node.kind == DocNodeKind.change);

  setUp(() {
    root = buildUpstreamSpec();
    source = PlatformFilesSource(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('спецификации проекта', () {
    test('клон upstream — каталоги openspec/specs, заголовок из H1', () {
      write('openspec/specs/auth/spec.md', '# auth Specification\n\n## Purpose\nВход.\n');
      final specs = specsNode()!;

      expect(specs.kind, DocNodeKind.specs);
      expect([for (final child in specs.children) child.id], ['auth', 'ui']);
      expect([for (final child in specs.children) child.title], ['auth Specification', 'ui Specification']);
      final ui = specs.children.last.docs.single;
      expect(ui.id, DocArtifact.specFileId);
      expect(ui.path, endsWith(p.join('openspec', 'specs', 'ui', 'spec.md')));
    });

    test('после групп и перед архивом', () {
      final ids = [for (final node in tree()) node.id];
      expect(ids.indexOf(PlatformFilesSource.specsNodeId), ids.length - 2);
      expect(ids.last, PlatformFilesSource.archiveNodeId);
    });

    test('вложенные каталоги, без H1 — имя каталога', () {
      write('openspec/specs/identity/user-auth/spec.md', 'Без заголовка.\n');
      final identity = specsNode()!.children.firstWhere((node) => node.id == 'identity');

      expect(identity.docs, isEmpty);
      expect(identity.children.single.id, p.join('identity', 'user-auth'));
      expect(identity.children.single.title, 'user-auth');
    });

    test('спецификаций нет — узла нет', () {
      Directory(p.join(root.path, 'openspec', 'specs')).deleteSync(recursive: true);
      expect(specsNode(), isNull);

      Directory(p.join(root.path, 'openspec', 'specs')).createSync();
      expect(specsNode(), isNull);
    });
  });

  group('дельты change\'а', () {
    test('change с двумя дельтами — строка на файл с операцией', () {
      write('openspec/changes/add-dark-mode/specs/auth/spec.md', '## ADDED Requirements\n\n### Requirement: Login\n');
      write(
        'openspec/changes/add-dark-mode/specs/ui/spec.md',
        '## MODIFIED Requirements\n\n### Requirement: Theme\n\n## ADDED Requirements\n',
      );
      final deltas = changeNode('add-dark-mode').docs.where((doc) => doc.id.startsWith('specs:')).toList();

      expect(
        [for (final doc in deltas) doc.fileName],
        [p.join('specs', 'auth', 'spec.md'), p.join('specs', 'ui', 'spec.md')],
      );
      expect(
        [for (final doc in deltas) doc.operations],
        [
          ['ADDED'],
          ['MODIFIED', 'ADDED'],
        ],
      );
      expect(deltas.every((doc) => doc.exists), isTrue);
    });

    test('у активного change\'а без файлов — одна серая строка', () {
      final specs = changeNode('refactor-config').docs.where((doc) => doc.id == 'specs').toList();

      expect(specs, hasLength(1));
      expect(specs.single.exists, isFalse);
      expect(specs.single.fileName, 'specs/**/*.md');
    });

    test('архивный change без дельт — строки «файлов нет» нет', () {
      final archived = tree().last.children.single;

      expect(archived.id, 'add-login');
      expect(archived.docs.where((doc) => doc.id == 'specs' || doc.id.startsWith('specs:')), isEmpty);
    });
  });
}
