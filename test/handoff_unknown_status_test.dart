import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/change_unit.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/feature_gate.dart';
import 'package:spok/domain/entities/group.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/entities/stack_state.dart';
import 'package:spok/domain/entities/status_semantics.dart';
import 'package:spok/domain/entities/task_item.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/handoff_screen.dart';
import 'package:spok/presentation/widgets/missing_key_block.dart';

/// Спека объявила статус передачи, группировку и семантику статусов —
/// ворота фичи открыты, экран передачи работает.
const _semantics = StatusSemantics(statuses: [
  TrackerStatus(id: 7, name: 'Ожидает тестирования'),
]);

const _group = Group(
    id: 'sp-1',
    title: 'Спринт 1',
    kind: GroupingKind.sprintDir,
    changeIds: ['mtm-03']);

/// Change без статуса: трекер не опрошен, а в `redmine.yaml` change'а
/// статуса нет — это и есть случай, из-за которого экран раньше молча
/// докладывал о готовности.
ChangeUnit _change() => ChangeUnit(
      id: 'mtm-03',
      title: 'Рассылка',
      dir: '/tmp',
      stackStates: {
        'backend': StackState(
            stack: 'backend', tasks: const [TaskItem('1.1', 'Шаг', true)]),
      },
    );

FeatureGate _gate(RequirementId id, {required bool satisfied}) => FeatureGate([
      FeatureRequirement(
          id: id, scope: RequirementScope.spec, satisfied: satisfied),
    ]);

final _features = {
  SpecFeature.handoff: FeatureGate([
    FeatureRequirement(
        id: RequirementId.grouping,
        scope: RequirementScope.spec,
        satisfied: true),
    FeatureRequirement(
        id: RequirementId.statusSemantics,
        scope: RequirementScope.spec,
        satisfied: true),
  ]),
  SpecFeature.builds: _gate(RequirementId.buildsFile, satisfied: false),
};

class _FakeRepository implements PlatformRepository {
  final RedmineProblem problem;

  _FakeRepository(this.problem);

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        groups: const [_group],
        changes: [_change()],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        profile: ProjectProfile(
          schema: const SpecSchema(name: 'avelacom', artifacts: []),
          stacks: const ['backend'],
          grouping: GroupingKind.sprintDir,
          statuses: _semantics,
          features: _features,
        ),
        redmineProblem: problem,
        refreshedAt: DateTime.now(),
      );

  @override
  Future<bool> setPlatformDir(String path) async => true;

  @override
  Future<bool> openInEditor(String absolutePath) async => true;

  @override
  String? get rootPath => '/tmp/spec';

  @override
  List<SlashCommand> slashCommands() => const [];

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() =>
      (changeIds: const [], groupIds: const []);

  @override
  String get role => '';

  @override
  String get roleKey => '';

  @override
  Future<String> readDoc(String absolutePath) async => '';

  @override
  Future<DocState> docState(String absolutePath) async => DocState.unknown;

  @override
  Future<List<IssueComment>> issueComments(List<int> issueIds) async =>
      const [];

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


void main() {
  group('Передача без статусов трекера', () {
    Future<ConsoleBloc> open(WidgetTester tester, RedmineProblem problem) async {
      final repository = _FakeRepository(problem);
      final console = ConsoleBloc(repository);
      final sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      tester.view.physicalSize = const Size(1400, 1000);
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
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: console),
              BlocProvider.value(value: sessions),
            ],
            child: const HandoffScreen(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return console;
    }

    testWidgets('экран остаётся, но готовность объявлена неизвестной',
        (tester) async {
      await open(tester, RedmineProblem.noApiKey);

      // Экран не спрятан: получателей и сборку человек собирает без трекера.
      expect(find.text('Готовность'), findsOneWidget);
      expect(find.text('Готовность неизвестна — статусы трекера не опрошены'),
          findsOneWidget);
      // Прежней строки «1 из 1 готовы» на экране больше нет.
      expect(find.textContaining("готовы к передаче"), findsNothing);
      expect(find.textContaining('статус не опрошен'), findsOneWidget);
    });

    testWidgets('ключа нет у меня — поле для него прямо в шаге',
        (tester) async {
      await open(tester, RedmineProblem.noApiKey);

      expect(find.byType(MissingKeyBlock), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
    });

    testWidgets('трекер молчит — не поле, а повтор запроса', (tester) async {
      await open(tester, RedmineProblem.unreachable);

      expect(find.byType(MissingKeyBlock), findsNothing);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('отправка недоступна и причина названа честно',
        (tester) async {
      await open(tester, RedmineProblem.noApiKey);

      final button = tester.widget<FilledButton>(
          find.ancestor(
              of: find.text('Отправить спринт тестировщику'),
              matching: find.byType(FilledButton)));
      expect(button.onPressed, isNull);
      expect(
          find.text('недоступно: статусы трекера не опрошены — '
              'готовность неизвестна'),
          findsOneWidget);
    });
  });
}
