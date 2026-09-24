import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/change_unit.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/group.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/spec_recognition.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/entities/stack_state.dart';
import 'package:spok/domain/entities/status_semantics.dart';
import 'package:spok/domain/entities/task_item.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/group_screen.dart';
import 'package:spok/presentation/ui_kit/skeleton.dart';
import 'package:spok/presentation/ui_kit/status_badge.dart';

/// Спека распознана целиком: блока «не распознано» в таком слепке нет.
const _fullRecognition = SpecRecognition([
  RecognizedItem(part: RecognizedPart.schema, recognized: true, value: 's'),
  RecognizedItem(part: RecognizedPart.grouping, recognized: true),
  RecognizedItem(part: RecognizedPart.stacks, recognized: true),
  RecognizedItem(part: RecognizedPart.statuses, recognized: true, value: '8'),
  RecognizedItem(part: RecognizedPart.commands, recognized: true, value: '9'),
  RecognizedItem(part: RecognizedPart.services, recognized: true, value: '1'),
]);

const _schema = SpecSchema(
  name: 'test-schema',
  artifacts: [SchemaArtifact(id: 'proposal', generates: 'proposal.md')],
);

/// Репозиторий, у которого слепок задаётся тестом, а загрузка может
/// намеренно не отвечать — так проверяется вид первой загрузки.
class _FakeRepository implements PlatformRepository {
  final ConsoleSnapshot? snapshot;

  /// Загрузка отвечает не сразу: так видно, что экран показывает, пока
  /// слепка ещё нет.
  final bool slowLoad;

  _FakeRepository({this.snapshot, this.slowLoad = false});

  @override
  Future<ConsoleSnapshot> load() async {
    await Future<void>.delayed(
        slowLoad ? const Duration(seconds: 2) : Duration.zero);
    return snapshot ?? _snapshot();
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
  Future<String> readDoc(String absolutePath) async => '';

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

ConsoleSnapshot _snapshot({
  List<ChangeUnit> changes = const [],
  List<Group> groups = const [],
  RedmineProblem problem = RedmineProblem.none,
  String problemDetail = '',
  SpecRecognition recognition = _fullRecognition,
}) =>
    ConsoleSnapshot(
      groups: groups,
      changes: changes,
      divergences: const [],
      env: const EnvReport(keys: [], repos: [], systems: []),
      profile: ProjectProfile(
        schema: _schema,
        stacks: const ['backend'],
        statuses: StatusSemantics.empty,
        recognition: recognition,
      ),
      redmineProblem: problem,
      redmineProblemDetail: problemDetail,
      refreshedAt: DateTime.now(),
    );

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
          child: const GroupScreen(),
        ),
      ),
    );

void main() {
  group('Состояния данных', () {
    late ConsoleBloc console;

    Future<void> open(WidgetTester tester, _FakeRepository repository) async {
      console = ConsoleBloc(repository);
      final sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(console, sessions));
      await tester.pump();
    }

    testWidgets('первая загрузка — скелет таблицы, а не лоадер в центре',
        (tester) async {
      await open(
          tester,
          _FakeRepository(
              slowLoad: true,
              snapshot: _snapshot(changes: [
                ChangeUnit(
                    id: 'mtm-03',
                    title: 'Рассылка',
                    dir: '/tmp',
                    stackStates: {
                      'backend': StackState(
                          stack: 'backend',
                          tasks: const [TaskItem('1.1', 'Шаг', false)]),
                    }),
              ])));

      // Слепка ещё нет: на месте таблицы — её скелет, а не крутящийся
      // индикатор вместо всего экрана.
      expect(find.byType(SkeletonRow), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Данные пришли — таблица встала на место скелета.
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(SkeletonRow), findsNothing);
      expect(find.text('Рассылка'), findsOneWidget);
    });

    testWidgets('трекер молчит — говорим, что показаны данные файлов, '
        'и даём повтор', (tester) async {
      await open(
          tester,
          _FakeRepository(
              snapshot: _snapshot(
            changes: [
              ChangeUnit(id: 'mtm-03', title: 'Рассылка', dir: '/tmp', stackStates: {
                'backend': StackState(
                    stack: 'backend',
                    cachedStatus: 'В работе',
                    tasks: const [TaskItem('1.1', 'Шаг', false)]),
              }),
            ],
            problem: RedmineProblem.noApiKey,
          )));
      await tester.pumpAndSettle();

      expect(
          find.text('Статусы трекера недоступны — показаны данные файлов спеки'),
          findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('статус из файла помечен и его точка полая', (tester) async {
      await open(
          tester,
          _FakeRepository(
              snapshot: _snapshot(changes: [
            ChangeUnit(id: 'mtm-03', title: 'Рассылка', dir: '/tmp', stackStates: {
              'backend': StackState(
                  stack: 'backend',
                  cachedStatus: 'В работе',
                  tasks: const [TaskItem('1.1', 'Шаг', false)]),
            }),
          ])));
      await tester.pumpAndSettle();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.text, contains('из файла'));
      expect(badge.hollow, isTrue);
    });

    testWidgets('пусто — объяснение, первый шаг и превью команды',
        (tester) async {
      await open(tester, _FakeRepository(snapshot: _snapshot()));
      await tester.pumpAndSettle();

      expect(find.text('В спеке пока нет change\'ей'), findsOneWidget);
      expect(find.text('Создать change'), findsOneWidget);
      // Что именно запустится — видно до нажатия.
      expect(find.textContaining('/opsx-propose'), findsOneWidget);
    });

    testWidgets('не распознанное показывается списком с «Указать вручную»',
        (tester) async {
      await open(
          tester,
          _FakeRepository(
              snapshot: _snapshot(
            changes: [
              ChangeUnit(id: 'mtm-03', title: 'Рассылка', dir: '/tmp', stackStates: {
                'backend': StackState(
                    stack: 'backend',
                    tasks: const [TaskItem('1.1', 'Шаг', false)]),
              }),
            ],
            recognition: const SpecRecognition([
              RecognizedItem(
                  part: RecognizedPart.schema, recognized: true, value: 'sdr'),
              RecognizedItem(
                  part: RecognizedPart.statuses,
                  recognized: false,
                  lookedIn: 'openspec/redmine.yaml'),
            ]),
          )));
      await tester.pumpAndSettle();

      expect(find.textContaining('Разобрано 1 из 2'), findsOneWidget);
      expect(find.text('Статусы трекера'), findsOneWidget);
      expect(find.text('не найдено'), findsOneWidget);
      expect(find.text('Указать вручную'), findsOneWidget);
    });

    testWidgets('спека разобрана целиком — блока «не распознано» нет',
        (tester) async {
      await open(
          tester,
          _FakeRepository(
              snapshot: _snapshot(changes: [
            ChangeUnit(id: 'mtm-03', title: 'Рассылка', dir: '/tmp', stackStates: {
              'backend': StackState(
                  stack: 'backend',
                  tasks: const [TaskItem('1.1', 'Шаг', false)]),
            }),
          ])));
      await tester.pumpAndSettle();

      expect(find.text('Указать вручную'), findsNothing);
    });
  });
}
