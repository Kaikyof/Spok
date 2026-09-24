import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/feature_gate.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/entities/spec_recognition.dart';
import 'package:spok/domain/entities/spec_schema.dart';
import 'package:spok/domain/entities/status_semantics.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/recognition_screen.dart';

/// Разбор чужой спеки: статусы трекера не объявлены — и это видно на шаге,
/// а не всплывает потом пустой таблицей.
const _recognition = SpecRecognition([
  RecognizedItem(
      part: RecognizedPart.schema,
      recognized: true,
      value: 'avelacom',
      lookedIn: 'openspec/schemas/*/schema.yaml',
      sourcePath: '/tmp/spec/openspec/schemas/avelacom/schema.yaml'),
  RecognizedItem(
      part: RecognizedPart.grouping,
      recognized: true,
      value: 'masterDoc',
      lookedIn: 'openspec/doc',
      sourcePath: '/tmp/spec/openspec/doc'),
  RecognizedItem(
      part: RecognizedPart.stacks,
      recognized: true,
      value: 'backend',
      lookedIn: 'schema.yaml → tasks-<stack>',
      sourcePath: '/tmp/spec/openspec/schemas/avelacom/schema.yaml'),
  // Файла нет вовсе — и пути к нему нет: «изменить» тут открывать нечего.
  RecognizedItem(
      part: RecognizedPart.statuses,
      recognized: false,
      lookedIn: 'openspec/redmine.yaml'),
  RecognizedItem(
      part: RecognizedPart.commands,
      recognized: true,
      value: '12',
      lookedIn: 'schema · .claude · package.json · Makefile'),
  RecognizedItem(
      part: RecognizedPart.services,
      recognized: true,
      value: '1',
      lookedIn: 'workspace.yaml → services',
      sourcePath: '/tmp/spec/workspace.yaml'),
]);

/// Передача выключена: в спеке нет команды передачи. Сборки работают.
/// Требования есть у каждой фичи: пустой gate значил бы «требований нет»,
/// то есть «работает», — а это не то же, что «не проверяли».
FeatureGate _gate(RequirementId id, {required bool satisfied}) => FeatureGate([
      FeatureRequirement(
          id: id, scope: RequirementScope.spec, satisfied: satisfied),
    ]);

final _features = {
  SpecFeature.handoff: _gate(RequirementId.handoverCommand, satisfied: false),
  SpecFeature.builds: _gate(RequirementId.buildsFile, satisfied: true),
  SpecFeature.mergeRequests:
      _gate(RequirementId.gitlabTokenDeclared, satisfied: false),
  SpecFeature.chat: _gate(RequirementId.chatKeysDeclared, satisfied: false),
  SpecFeature.multiStack: _gate(RequirementId.stacks, satisfied: false),
};

class _FakeRepository implements PlatformRepository {
  /// Что открывали в редакторе: шаг обещает открыть файл спеки — проверяем,
  /// что открывается именно он.
  final opened = <String>[];

  bool accepted = true;

  /// Реестр подключённых спек: из него видно, новая спека или человек
  /// вернулся к уже подключённой.
  List<String> registry = const [];

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        groups: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        profile: ProjectProfile(
          schema: const SpecSchema(name: 'avelacom', artifacts: []),
          stacks: const ['backend'],
          statuses: StatusSemantics.empty,
          features: _features,
          recognition: _recognition,
        ),
        redmineProblem: RedmineProblem.none,
        refreshedAt: DateTime.now(),
      );

  @override
  Future<bool> setPlatformDir(String path) async => accepted;

  @override
  Future<bool> openInEditor(String absolutePath) async {
    opened.add(absolutePath);
    return true;
  }

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
  Future<List<String>> knownSpecs() async => registry;

  @override
  Future<EnvForm> envForm() async => EnvForm.empty;

  @override
  Future<Map<String, String>> readEnvFile(String path) async => const {};

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
  group('Шаг «Что распознано»', () {
    late _FakeRepository repository;
    late ConsoleBloc console;
    late SessionsBloc sessions;

    Future<void> open(WidgetTester tester) async {
      repository = _FakeRepository();
      console = ConsoleBloc(repository);
      sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      tester.view.physicalSize = const Size(1280, 900);
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
            child: const RecognitionScreen(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('подключение спеки ведёт на разбор, а не сразу на экраны',
        (tester) async {
      await open(tester);
      console.add(PlatformPathSubmitted('/tmp/spec'));
      await tester.pumpAndSettle();

      expect(console.state.recognitionReview, isTrue);
      expect(console.state.needsSetup, isTrue);
    });

    testWidgets('спека из списка открывается сразу — разбор её уже смотрели',
        (tester) async {
      await open(tester);
      repository.registry = const ['/tmp/spec'];
      // Реестр попадает в состояние обычным обновлением.
      console.add(ConsoleRefreshed());
      await tester.pumpAndSettle();

      console.add(PlatformPathSubmitted('/tmp/spec/'));
      await tester.pumpAndSettle();

      expect(console.state.recognitionReview, isFalse);
      expect(console.state.needsSetup, isFalse);
    });

    testWidgets('непринятый путь оставляет человека на адресе, без разбора',
        (tester) async {
      await open(tester);
      repository.accepted = false;
      console.add(PlatformPathSubmitted('/tmp/not-a-spec'));
      await tester.pumpAndSettle();

      expect(console.state.recognitionReview, isFalse);
      expect(console.state.pathRejected, isTrue);
    });

    testWidgets('сводка считает разобранное, нераспознанное названо словами',
        (tester) async {
      await open(tester);

      expect(find.text('Разобрано 5 требований из 6'), findsOneWidget);
      expect(find.text('Статусы трекера'), findsOneWidget);
      expect(find.text('не найдено'), findsOneWidget);
      expect(find.text('openspec/redmine.yaml'), findsOneWidget);
    });

    testWidgets('матрица показывает выключенную фичу и чего ей не хватает',
        (tester) async {
      await open(tester);

      expect(find.text('работает'), findsOneWidget);
      expect(find.text('выключено'), findsWidgets);
      expect(
          find.textContaining('не хватает: Команда передачи'), findsOneWidget);
    });

    testWidgets('«Изменить» открывает тот файл спеки, который решает',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Изменить').first);
      await tester.pumpAndSettle();

      expect(repository.opened,
          ['/tmp/spec/openspec/schemas/avelacom/schema.yaml']);
    });

    testWidgets('у собранного из нескольких источников кнопки правки нет',
        (tester) async {
      await open(tester);

      // Шесть частей; у команд источников несколько, у статусов файла нет
      // вовсе — кнопок четыре.
      expect(find.text('Изменить'), findsNWidgets(4));
      expect(find.text('собрано из нескольких источников'), findsNWidgets(2));
    });

    testWidgets('«Открыть спеку» закрывает шаг — дальше обычные экраны',
        (tester) async {
      await open(tester);

      // Разбор длиннее окна — до кнопок доезжают прокруткой.
      await tester.ensureVisible(find.text('Открыть спеку'));
      await tester.tap(find.text('Открыть спеку'));
      await tester.pumpAndSettle();

      expect(console.state.recognitionReview, isFalse);
      expect(console.state.needsSetup, isFalse);
    });

    testWidgets('«Указать другой адрес» возвращает к подключению',
        (tester) async {
      await open(tester);

      await tester.ensureVisible(find.text('Указать другой адрес'));
      await tester.tap(find.text('Указать другой адрес'));
      await tester.pumpAndSettle();

      expect(console.state.recognitionReview, isFalse);
      expect(console.state.switchingSpec, isTrue);
    });
  });
}
