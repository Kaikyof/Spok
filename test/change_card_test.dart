import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/change_unit.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/group.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/entities/stack_state.dart';
import 'package:spok/domain/entities/task_item.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/change_screen.dart';

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

class _FakeRepository implements PlatformRepository {
  final Directory changeDir;

  _FakeRepository(this.changeDir);

  ChangeUnit get change => ChangeUnit(
        id: 'mtm-03',
        title: 'Рассылка из мастер-тикета',
        dir: changeDir.path,
        stackStates: {
          'backend': StackState(
            stack: 'backend',
            issueId: 63592,
            cachedStatus: 'В работе',
            tasks: const [
              TaskItem('1.1', 'Собрать получателей', true),
              TaskItem('1.2', 'Отправить письмо', false),
            ],
          ),
        },
      );

  @override
  List<SlashCommand> slashCommands() => const [
        SlashCommand(
            id: 'opsx-apply',
            description: 'Реализация задач change\'а',
            argumentHint: '[change] [stack]'),
        SlashCommand(
            id: 'opsx-submit',
            description: 'Отдать на ревью',
            argumentHint: '[change] [stack]'),
        SlashCommand(
            id: 'opsx-explore',
            description: 'Разобраться в спеке',
            argumentHint: ''),
      ];

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() =>
      (changeIds: ['mtm-03'], groupIds: const []);

  @override
  String? get rootPath => changeDir.parent.path;

  @override
  String get role => 'backend';

  @override
  String get roleKey => 'SPEC_ROLE';

  /// Вторая группа со своим change'ем: между ними переключаются в шапке.
  ChangeUnit get otherChange => ChangeUnit(
        id: 'mtm-04',
        title: 'Письмо поставщику',
        dir: changeDir.path,
        groupId: 'supplier',
        stackStates: {
          'backend': StackState(
              stack: 'backend', tasks: const [TaskItem('1.1', 'Шаблон', false)]),
        },
      );

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        groups: const [
          Group(
              id: 'broadcast',
              title: 'Рассылка',
              kind: GroupingKind.masterDoc,
              changeIds: ['mtm-03']),
          Group(
              id: 'supplier',
              title: 'Поставщики',
              kind: GroupingKind.masterDoc,
              changeIds: ['mtm-04']),
        ],
        changes: [change, otherChange],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        profile: const ProjectProfile(schema: _schema, stacks: ['backend']),
        redmineProblem: RedmineProblem.none,
        refreshedAt: DateTime.now(),
      );

  @override
  // Синхронное чтение: в фейковом времени теста настоящий ввод-вывод
  // не успевает завершиться до проверок.
  Future<String> readDoc(String absolutePath) async =>
      File(absolutePath).readAsStringSync();

  @override
  Future<DocState> docState(String absolutePath) async => DocState.unknown;

  @override
  Future<bool> openInEditor(String absolutePath) async => false;

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

  @override
  Stream<CloneProgress> cloneSpec(String url, {String ref = ''}) =>
      const Stream.empty();

  @override
  void cancelClone() {}
}

Widget _wrap(ConsoleBloc console, SessionsBloc sessions) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: console),
            BlocProvider.value(value: sessions),
          ],
          child: const ChangeScreen(),
        ),
      ),
    );

void main() {
  group('Карточка change', () {
    late Directory root;
    late Directory changeDir;
    late _FakeRepository repository;
    late ConsoleBloc console;
    late SessionsBloc sessions;

    setUp(() {
      root = Directory.systemTemp.createTempSync('change-card-test');
      changeDir = Directory('${root.path}/openspec/changes/mtm-03')
        ..createSync(recursive: true);
      repository = _FakeRepository(changeDir);
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<void> openCard(WidgetTester tester) async {
      console = ConsoleBloc(repository);
      sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(console, sessions));
      await tester.pumpAndSettle();
      console.add(ChangeOpened(repository.change));
      await tester.pumpAndSettle();
    }

    testWidgets('главный текст карточки — спека изменения, не задачи',
        (tester) async {
      File('${changeDir.path}/proposal.md')
          .writeAsStringSync('## Зачем\n\nПисьма должны уходить всем.');
      await openCard(tester);

      expect(find.text('Спека изменения'), findsOneWidget);
      expect(find.textContaining('Письма должны уходить всем'), findsOneWidget);
      // Задачи никуда не делись — они ниже спеки.
      expect(find.textContaining('Собрать получателей'), findsOneWidget);
    });

    testWidgets('спеки нет — говорим об этом и показываем ожидаемый файл',
        (tester) async {
      await openCard(tester);

      expect(find.text('Спека ещё не написана'), findsOneWidget);
      expect(find.textContaining('proposal.md'), findsWidgets);
    });

    testWidgets('артефакт ждёт предшественника по requires', (tester) async {
      File('${changeDir.path}/proposal.md').writeAsStringSync('текст');
      await openCard(tester);

      // design ещё не написан, но и писать его рано: требует proposal…
      expect(find.text('1 из 3 артефактов заполнены'), findsOneWidget);
      // …а задачи стека ждут дизайна.
      expect(find.textContaining('ждёт: '), findsWidgets);
    });

    testWidgets('смена группы закрывает карточку change\'а прежней группы',
        (tester) async {
      File('${changeDir.path}/proposal.md').writeAsStringSync('текст спеки');
      await openCard(tester);
      expect(find.text('Спека изменения'), findsOneWidget);

      console.add(GroupSelected('supplier'));
      await tester.pumpAndSettle();

      // Карточка закрылась, и виден список change'ей новой группы.
      expect(find.text('Спека изменения'), findsNothing);
      expect(find.text('Письмо поставщику'), findsOneWidget);
      expect(find.text('Рассылка из мастер-тикета'), findsNothing);
      expect(console.state.changeSpec, isNull);
    });

    testWidgets('меню действий собрано из сигнатур команд спеки',
        (tester) async {
      await openCard(tester);

      await tester.tap(find.text('Ещё действия'));
      await tester.pumpAndSettle();

      // Команда с [change] попадает в меню, без аргументов — нет,
      // а роль «реализовать» уже вынесена отдельной кнопкой.
      expect(find.text('/opsx-submit'), findsOneWidget);
      expect(find.text('/opsx-explore'), findsNothing);
      expect(find.text('/opsx-apply'), findsNothing);
    });

    testWidgets('выбор действия подставляет команду с известными аргументами',
        (tester) async {
      await openCard(tester);

      await tester.tap(find.text('Ещё действия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('/opsx-submit'));
      await tester.pumpAndSettle();

      expect(sessions.state.draft, '/opsx-submit mtm-03 --stack backend ');
      expect(console.state.screen, ConsoleScreen.sessions);
    });
  });
}
