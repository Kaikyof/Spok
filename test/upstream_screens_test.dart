import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/data/repositories/platform_repository_impl.dart';
import 'package:spok/data/sources/platform_files_source.dart';
import 'package:spok/domain/entities/clone_progress.dart';
import 'package:spok/domain/entities/console_snapshot.dart';
import 'package:spok/domain/entities/doc_state.dart';
import 'package:spok/domain/entities/env_field.dart';
import 'package:spok/domain/entities/handoff_recipient.dart';
import 'package:spok/domain/entities/issue_comment.dart';
import 'package:spok/domain/entities/merge_request_info.dart';
import 'package:spok/domain/entities/secret_backend.dart';
import 'package:spok/domain/entities/slash_command.dart';
import 'package:spok/domain/repositories/platform_repository.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/bloc/console_bloc.dart';
import 'package:spok/presentation/bloc/sessions_bloc.dart';
import 'package:spok/presentation/screens/change_screen.dart';
import 'package:spok/presentation/screens/env_screen.dart';
import 'package:spok/presentation/screens/group_screen.dart';
import 'package:spok/presentation/screens/recognition_screen.dart';

import 'upstream_fixture.dart';

/// Слепок читается настоящим репозиторием с фикстуры upstream, а экранам
/// отдаётся через заглушку: в фейковом времени виджет-теста живой
/// ввод-вывод не успевает, а поведение экранов на проекте без трекера
/// надо проверять на том, что прочитал код, а не на выдуманном слепке.
class _SnapshotRepository implements PlatformRepository {
  final ConsoleSnapshot snapshot;
  final List<SlashCommand> commands;

  _SnapshotRepository(this.snapshot, this.commands);

  @override
  Future<ConsoleSnapshot> load() async => snapshot;

  @override
  List<SlashCommand> slashCommands() => commands;

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() => (
        changeIds: snapshot.changes.map((change) => change.id).toList(),
        groupIds: const [],
      );

  @override
  String? get rootPath => '/tmp/upstream';

  @override
  String get role => '';

  @override
  String get roleKey => '';

  @override
  Future<String> readDoc(String absolutePath) async =>
      File(absolutePath).readAsStringSync();

  @override
  Future<DocState> docState(String absolutePath) async => DocState.unknown;

  @override
  Future<bool> openInEditor(String absolutePath) async => false;

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
  Future<bool> setPlatformDir(String path) async => true;

  @override
  Future<List<String>> knownSpecs() async => const [];

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
  late Directory root;
  late ConsoleSnapshot snapshot;
  late List<SlashCommand> commands;

  setUpAll(() async {
    root = buildUpstreamSpec();
    final source = PlatformFilesSource(root);
    snapshot = await PlatformRepositoryImpl(source).load();
    commands = source.loadSlashCommands();
  });

  tearDownAll(() => root.deleteSync(recursive: true));

  late ConsoleBloc console;

  Future<void> open(WidgetTester tester, Widget screen) async {
    final repository = _SnapshotRepository(snapshot, commands);
    console = ConsoleBloc(repository);
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
          child: screen,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('Проект оригинального OpenSpec', () {
    testWidgets('таблица: у каждого change\'а стадия, слов «нет доступа» '
        'и имён трекера нет', (tester) async {
      await open(tester, const GroupScreen());

      // add-dark-mode: четыре задачи, одна закрыта — в работе.
      expect(find.text('в работе · 1/4'), findsOneWidget);
      // refactor-config: proposal и tasks есть, design нет и его ничто
      // не держит — планирование, следующий артефакт назван.
      expect(find.text('планирование · ждёт Дизайн-решения'), findsOneWidget);
      expect(find.text('нет доступа'), findsNothing);
      expect(find.textContaining('Redmine'), findsNothing);
      // Полосы о ключе трекера нет: трекера у процесса нет по замыслу.
      expect(find.textContaining('Статусы трекера недоступны'), findsNothing);
      // Статусы трекера не считаются непонятыми: строки о них нет.
      expect(find.text('Статусы трекера'), findsNothing);
    });

    testWidgets('следующий шаг — по стадии самого отстающего change\'а',
        (tester) async {
      await open(tester, const GroupScreen());

      expect(
          find.textContaining(
              'Следующий шаг: написать Дизайн-решения для change’а '
              '«refactor-config»'),
          findsOneWidget);
    });

    testWidgets('карточка: стадия в шапке, ленты комментариев трекера нет',
        (tester) async {
      await open(tester, const ChangeScreen());
      final change =
          snapshot.changes.singleWhere((c) => c.id == 'add-dark-mode');
      console.add(ChangeOpened(change));
      await tester.pumpAndSettle();

      expect(find.text('в работе · 1/4'), findsOneWidget);
      expect(find.textContaining('Комментарии'), findsNothing);
      expect(find.textContaining('Redmine'), findsNothing);
      expect(find.text('нет доступа'), findsNothing);
    });

    testWidgets('окружение: без .env.example нет ни ключей, ни систем, '
        'ни кнопки «Заполнить ключи»', (tester) async {
      await open(tester, const EnvScreen());

      expect(find.text('Заполнить ключи'), findsNothing);
      expect(find.text('Внешние системы'), findsNothing);
      expect(find.textContaining('Ключи в .env'), findsNothing);
      expect(find.textContaining('Спека не объявляет ключей'), findsOneWidget);
      expect(find.textContaining('Redmine'), findsNothing);
    });

    testWidgets('разбор: схема названа со своим источником, строки '
        'статусов трекера нет', (tester) async {
      await open(tester, const RecognitionScreen());

      expect(find.textContaining('spec-driven · встроенная схема upstream'),
          findsOneWidget);
      expect(find.text('Статусы трекера'), findsNothing);
      expect(find.textContaining('Redmine'), findsNothing);
    });
  });
}
