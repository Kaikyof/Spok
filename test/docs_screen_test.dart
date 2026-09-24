import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spok/core/resources/app_colors.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/doc_artifact.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_node.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/screens/docs_screen.dart';

/// Схема спеки: спека изменения, дизайн после неё, задачи стека.
const _schema = SpecSchema(
  name: 'test-schema',
  artifacts: [
    SchemaArtifact(id: 'proposal', generates: 'proposal.md'),
    SchemaArtifact(
        id: 'design', generates: 'design.md', requires: ['proposal']),
    SchemaArtifact(
        id: 'tasks-backend',
        generates: 'tasks_backend.md',
        requires: ['design']),
  ],
);

/// Спека avelacom-образца: мастер-спека одним файлом, change в работе
/// и один сданный в архив с датой в имени каталога.
Directory _buildSpec() {
  final root = Directory.systemTemp.createTempSync('docs-screen');
  void write(String relativePath, String content) {
    final file = File(p.join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  write('workspace.yaml', 'services: []\n');
  write('openspec/config.yaml', 'schema: test-schema\n');
  write('openspec/schemas/test-schema/schema.yaml', '''
name: test-schema
artifacts:
  - id: proposal
    generates: proposal.md
  - id: design
    generates: design.md
    requires:
      - proposal
  - id: tasks-backend
    generates: tasks_backend.md
    requires:
      - design
''');
  write('openspec/doc/pin-auth.md',
      '# pin-auth — Локальный вход: master-spec\n\nchanges: mtm-03\n');
  write('openspec/changes/mtm-03/proposal.md',
      '## Зачем\n\nПисьма должны уходить всем.\n');
  write('openspec/changes/mtm-03/redmine.yaml', 'version: 3\nstacks: {}\n');
  write('openspec/changes/archive/2026-07-31-mtm-01/proposal.md',
      '## Что сделали\n\nПервый заход.\n');
  return root;
}

class _FakeRepository implements PlatformRepository {
  final ConsoleSnapshot snapshot;

  _FakeRepository(this.snapshot);

  @override
  Future<ConsoleSnapshot> load() async => snapshot;

  @override
  // Синхронное чтение: в фейковом времени теста настоящий ввод-вывод
  // не успевает завершиться до проверок.
  Future<String> readDoc(String absolutePath) async =>
      File(absolutePath).readAsStringSync();

  @override
  Future<DocState> docState(String absolutePath) async =>
      const DocState(branch: 'main', file: DocFileState.modified);

  String? openedInEditor;

  @override
  Future<bool> openInEditor(String absolutePath) async {
    openedInEditor = absolutePath;
    return true;
  }

  @override
  List<SlashCommand> slashCommands() => const [];

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() =>
      (changeIds: const [], groupIds: const []);

  @override
  String? get rootPath => '/tmp/spec';

  @override
  String get role => '';

  @override
  String get roleKey => '';

  @override
  Future<List<IssueComment>> issueComments(List<int> issueIds) async => const [];

  @override
  Future<List<MergeRequestInfo>> mergeRequests(String changeId,
          {String groupId = ''}) async =>
      const [];

  @override
  Future<HandoffRecipients> handoffRecipients(String stack) async =>
      const HandoffRecipients();

  @override
  Future<String> configFilePath() async => '/tmp/fake-config/.env';

  @override
  Future<bool> setPlatformDir(String path) async => true;

  @override
  Future<List<String>> knownSpecs() async => const [];

  @override
  Future<EnvForm> envForm() async => EnvForm.empty;

  @override
  Future<void> saveEnv(Map<String, String> values) async {}

  @override
  Future<SecretBackend> secretBackend() async => SecretBackend.file;
}

Widget _wrap(ConsoleBloc console) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: BlocProvider.value(value: console, child: const DocsScreen()),
      ),
    );

void main() {
  late Directory root;
  late PlatformFilesSource source;

  setUp(() {
    root = _buildSpec();
    source = PlatformFilesSource(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('Дерево документов', () {
    test('архивный change приходит с датой из имени и очищенным id', () {
      final archived = source.loadArchivedChanges();

      expect(archived, hasLength(1));
      expect(archived.single.id, 'mtm-01');
      expect(archived.single.archivedAt, DateTime(2026, 7, 31));
      expect(archived.single.archived, isTrue);
      // Архив не подмешивается к работе в текущих change'ах.
      expect(source.loadChanges().map((change) => change.id), ['mtm-03']);
    });

    test('мастер-спека лежит файлом — она документ самой группы', () {
      final changes = source.loadChanges();
      final tree = source.loadDocTree(source.loadGroups(changes), changes);
      final group = tree.first;

      expect(group.kind, DocNodeKind.group);
      expect(group.title, 'Локальный вход');
      expect(group.docs.single.fileName, 'pin-auth.md');
      expect(group.docs.single.id, DocArtifact.masterDocId);
      expect(group.docs.single.exists, isTrue);
    });

    test('объявленный схемой, но не написанный файл остаётся в дереве', () {
      final changes = source.loadChanges();
      final tree = source.loadDocTree(source.loadGroups(changes), changes);
      final change = tree.first.children.single;

      expect(change.id, 'mtm-03');
      expect([for (final doc in change.docs) doc.fileName],
          ['proposal.md', 'design.md', 'tasks_backend.md']);
      expect([for (final doc in change.docs) doc.exists],
          [true, false, false]);
      expect(change.presentCount, 1);
      expect(change.declaredCount, 3);
    });

    test('архив — отдельный узел в конце дерева, без ненаписанных файлов', () {
      final changes = source.loadChanges();
      final tree = source.loadDocTree(source.loadGroups(changes), changes,
          archived: source.loadArchivedChanges());
      final archived = tree.last.children.single;

      expect(tree.last.id, PlatformFilesSource.archiveNodeId);
      expect(archived.archivedAt, DateTime(2026, 7, 31));
      // Работа сдана: в архиве видно только то, что действительно написано.
      expect([for (final doc in archived.docs) doc.fileName], ['proposal.md']);
    });
  });

  group('Экран «Документы»', () {
    late _FakeRepository repository;
    late ConsoleBloc console;

    Future<void> openScreen(WidgetTester tester) async {
      final changes = source.loadChanges();
      final groups = source.loadGroups(changes);
      repository = _FakeRepository(ConsoleSnapshot(
        groups: groups,
        changes: changes,
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        docs: source.loadDocTree(groups, changes,
            archived: source.loadArchivedChanges()),
        profile: const ProjectProfile(schema: _schema, stacks: ['backend']),
        redmineProblem: RedmineProblem.none,
        refreshedAt: DateTime.now(),
      ));
      console = ConsoleBloc(repository);
      addTearDown(console.close);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(console));
      await tester.pumpAndSettle();
    }

    testWidgets('дерево показывает группу, change и архив с датой',
        (tester) async {
      await openScreen(tester);

      expect(find.text('Локальный вход'), findsOneWidget);
      expect(find.text('Рассылка'), findsNothing); // чужой спеки здесь нет
      expect(find.text('Архив'), findsOneWidget);
      expect(find.text('в архиве с 31 июля 2026'), findsOneWidget);
    });

    testWidgets('ненаписанный артефакт виден и не открывается',
        (tester) async {
      await openScreen(tester);

      expect(find.text('объявлен схемой, файла нет'), findsWidgets);
      await tester.tap(find.text('Дизайн-решения'));
      await tester.pumpAndSettle();

      expect(console.state.openedDoc, isNull);
      expect(find.text('Выберите документ слева'), findsOneWidget);
    });

    testWidgets('выбранный документ читается и показывает состояние ветки',
        (tester) async {
      await openScreen(tester);

      // Первая «Спека» в дереве — у change'а в работе, вторая у архивного.
      await tester.tap(find.text('Спека').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Письма должны уходить всем'), findsOneWidget);
      expect(find.text('изменён локально · main'), findsOneWidget);
    });

    testWidgets('строка файла подсвечивается под курсором', (tester) async {
      await openScreen(tester);
      final row = find.text('Спека').first;
      Color? background() => tester
          .widgetList<Container>(find.ancestor(
              of: row, matching: find.byType(Container)))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .first
          .color;

      expect(background(), isNull);

      final mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(row));
      await tester.pumpAndSettle();

      expect(background(), AppColors.card);

      // Ненаписанный файл открывать нечем — его и не подсвечиваем.
      await mouse.moveTo(tester.getCenter(find.text('Дизайн-решения').first));
      await tester.pumpAndSettle();
      expect(background(), isNull);
      expect(
          tester
              .widgetList<Container>(find.ancestor(
                  of: find.text('Дизайн-решения').first,
                  matching: find.byType(Container)))
              .map((container) => container.decoration)
              .whereType<BoxDecoration>()
              .first
              .color,
          isNull);
    });

    testWidgets('«Открыть в IDE» отдаёт редактору путь к файлу',
        (tester) async {
      await openScreen(tester);
      // Первая «Спека» в дереве — у change'а в работе, вторая у архивного.
      await tester.tap(find.text('Спека').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Открыть в IDE'));
      await tester.pumpAndSettle();

      expect(repository.openedInEditor,
          endsWith('openspec/changes/mtm-03/proposal.md'));
    });
  });
}
