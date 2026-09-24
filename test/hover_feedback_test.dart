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
import 'package:flutter/gestures.dart';
import 'package:spok/core/resources/app_colors.dart';
import 'package:spok/presentation/screens/group_screen.dart';
import 'package:spok/presentation/ui_kit/tappable.dart';

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

  _FakeRepository({this.snapshot});

  @override
  Future<ConsoleSnapshot> load() async => snapshot ?? _snapshot();

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

/// Плёнка под курсором — единственный видимый признак наведения: `InkWell`
/// рисовал чернила за непрозрачным фоном карточки, и их не было видно.
Color? _overlayOf(WidgetTester tester, Finder tappable) {
  final container = tester.widget<Container>(find
      .descendant(of: tappable, matching: find.byType(Container))
      .first);
  final decoration = container.foregroundDecoration as BoxDecoration?;
  return decoration?.color;
}

MouseCursor _cursorOf(WidgetTester tester, Finder tappable) =>
    tester
        .widget<MouseRegion>(
            find.descendant(of: tappable, matching: find.byType(MouseRegion)).first)
        .cursor;

void main() {
  group('Фидбэк наведения', () {
    testWidgets('нажимаемое место меняет курсор и подсвечивается',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Tappable(
              onTap: () {},
              child: const SizedBox(width: 120, height: 40),
            ),
          ),
        ),
      ));
      final tappable = find.byType(Tappable);

      expect(_cursorOf(tester, tappable), SystemMouseCursors.click);
      expect(_overlayOf(tester, tappable), isNull);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(tappable));
      await tester.pumpAndSettle();

      expect(_overlayOf(tester, tappable), AppColors.hoverOverlay);

      // Ушли — подсветка ушла с курсором, а не осталась висеть.
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(_overlayOf(tester, tappable), isNull);
    });

    testWidgets('выключенное место не обещает нажатия', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Tappable(child: SizedBox(width: 120, height: 40)),
          ),
        ),
      ));
      final tappable = find.byType(Tappable);

      expect(_cursorOf(tester, tappable), MouseCursor.defer);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(tappable));
      await tester.pumpAndSettle();

      expect(_overlayOf(tester, tappable), isNull);
    });

    testWidgets('когда жест берёт родитель, нажатие до него доходит',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () => taps++,
              child: const Tappable(
                tapHandledAbove: true,
                child: SizedBox(width: 120, height: 40),
              ),
            ),
          ),
        ),
      ));
      final tappable = find.byType(Tappable);

      expect(_cursorOf(tester, tappable), SystemMouseCursors.click);
      await tester.tap(tappable);
      expect(taps, 1);
    });

    testWidgets('карточка change\'а на живом экране отвечает на наведение',
        (tester) async {
      final repository = _FakeRepository(
          snapshot: _snapshot(
        groups: [
          const Group(
              id: 'sp-1',
              title: 'Спринт 1',
              kind: GroupingKind.sprintDir,
              changeIds: ['mtm-03'])
        ],
        changes: [
          ChangeUnit(id: 'mtm-03', title: 'Рассылка', dir: '/tmp', stackStates: {
            'backend': StackState(
                stack: 'backend',
                cachedStatus: 'В работе',
                tasks: const [TaskItem('1.1', 'Шаг', false)]),
          }),
        ],
      ));
      final console = ConsoleBloc(repository);
      final sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: console),
            BlocProvider.value(value: sessions),
          ],
          child: const GroupScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      final row = find
          .ancestor(of: find.text('Рассылка'), matching: find.byType(Tappable))
          .first;
      expect(_cursorOf(tester, row), SystemMouseCursors.click);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Рассылка')));
      await tester.pumpAndSettle();

      expect(_overlayOf(tester, row), AppColors.hoverOverlay);
    });
  });
}
