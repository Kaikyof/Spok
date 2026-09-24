import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_check.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/env_report.dart';
import 'package:spok/domain/entities/env_task.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/project_profile.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/env_screen.dart';
import 'package:spok/presentation/widgets/env_editor_dialog.dart';

class _FakeRepository implements PlatformRepository {
  /// Команды окружения, распознанные в спеке: у одной спеки они есть,
  /// у другой нет вовсе.
  final Map<EnvTask, SlashCommand> envCommands;

  /// Что прочитано из принесённого человеком файла.
  final Map<String, String> fileValues;

  _FakeRepository({this.envCommands = const {}, this.fileValues = const {}});

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        groups: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(
          keys: [
            EnvCheck(
                level: CheckLevel.error,
                name: 'REDMINE_API_KEY',
                outcome: CheckOutcome.keyMissing),
          ],
          repos: [
            EnvCheck(
                level: CheckLevel.error,
                name: 'avelacom-odoo',
                subtitle: 'develop',
                outcome: CheckOutcome.repoNotCloned),
          ],
          systems: [],
        ),
        profile: ProjectProfile(envCommands: envCommands),
        redmineProblem: RedmineProblem.none,
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
  Future<EnvForm> envForm() async => const EnvForm(
        fields: [
          EnvField(
              key: 'OPENSPEC_REPO_URL',
              value: '',
              hint: 'OpenSpec repo — blob URL for clickable links in Redmine '
                  'issue description (GitLab/GitHub)',
              optional: true),
        ],
        ignoredByGit: true,
        path: '/tmp/spec/.env',
      );

  @override
  Future<Map<String, String>> readEnvFile(String path) async => fileValues;

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
  group('Окружение', () {
    late ConsoleBloc console;
    late SessionsBloc sessions;

    /// [settle] выключают там, где на экране заведомо крутится индикатор
    /// ожидания: форма ключей до ответа репозитория.
    Future<void> open(WidgetTester tester, Widget screen,
        {Map<EnvTask, SlashCommand> envCommands = const {},
        bool settle = true}) async {
      final repository = _FakeRepository(envCommands: envCommands);
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
            child: screen,
          ),
        ),
      ));
      settle ? await tester.pumpAndSettle() : await tester.pump();
    }

    testWidgets('у раздела стоит распознанная команда спеки, а не «make init»',
        (tester) async {
      await open(tester, const EnvScreen(), envCommands: const {
        EnvTask.repos: SlashCommand(
            id: 'workspace:init',
            description: 'Склонировать репозитории workspace.yaml',
            source: CommandSource.packageScript,
            runLine: 'pnpm workspace:init'),
      });

      expect(find.text('pnpm workspace:init'), findsOneWidget);
      // Придуманной кнопки нет: имя команды берётся из спеки.
      expect(find.text('make init'), findsNothing);
    });

    testWidgets('команда уходит в сессию, а не выполняется молча',
        (tester) async {
      await open(tester, const EnvScreen(), envCommands: const {
        EnvTask.repos: SlashCommand(
            id: 'workspace:init',
            description: '',
            source: CommandSource.packageScript,
            runLine: 'pnpm workspace:init'),
      });

      await tester.tap(find.text('pnpm workspace:init'));
      await tester.pumpAndSettle();

      expect(sessions.state.draft, 'pnpm workspace:init');
      expect(console.state.screen, ConsoleScreen.sessions);
    });

    testWidgets('спека без таких команд не получает кнопок', (tester) async {
      await open(tester, const EnvScreen());

      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('в форме ключей описание видно целиком, а не до многоточия',
        (tester) async {
      await open(tester, const EnvEditorDialog(), settle: false);
      console.add(EnvFormRequested());
      await tester.pumpAndSettle();

      const hint = 'OpenSpec repo — blob URL for clickable links in Redmine '
          'issue description (GitLab/GitHub)';
      final text = tester.widget<Text>(find.text(hint));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('импорт подставляет значения и называет чужие ключи',
        (tester) async {
      final repository = _FakeRepository(fileValues: const {
        'OPENSPEC_REPO_URL': 'https://gitlab.example.com/spec/-/blob/master',
        'SOME_OTHER_KEY': 'значение из чужой спеки',
      });
      console = ConsoleBloc(repository);
      sessions = SessionsBloc(repository);
      addTearDown(console.close);
      addTearDown(sessions.close);
      // Системный диалог выбора файла в тесте не открыть — подменяем его.
      envFilePicker = () async => '/tmp/принесённый.env';
      addTearDown(() => envFilePicker = () async => null);
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
            child: const EnvEditorDialog(),
          ),
        ),
      ));
      await tester.pump();
      console.add(EnvFormRequested());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Импортировать из файла…'));
      await tester.pumpAndSettle();

      // Значение подставлено в поле — и только: записи ещё не было.
      expect(
          find.text('https://gitlab.example.com/spec/-/blob/master'),
          findsOneWidget);
      expect(find.textContaining('Подставлено 1 значение'), findsOneWidget);
      // Ключ, которого спека не спрашивает, назван поимённо.
      expect(find.textContaining('SOME_OTHER_KEY'), findsOneWidget);
      expect(console.state.envSaving, isFalse);
    });

    testWidgets('в форме ключей есть импорт из файла и он объяснён',
        (tester) async {
      await open(tester, const EnvEditorDialog(), settle: false);
      console.add(EnvFormRequested());
      await tester.pumpAndSettle();

      expect(find.text('Импортировать из файла…'), findsOneWidget);
      // Значения подставятся, но не сохранятся сами — это сказано прямо.
      expect(find.textContaining('только подставятся'), findsOneWidget);
    });
  });
}
