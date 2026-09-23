import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_console/core/resources/app_dimens.dart';
import 'package:platform_console/domain/entities/console_snapshot.dart';
import 'package:platform_console/domain/entities/env_field.dart';
import 'package:platform_console/domain/entities/env_report.dart';
import 'package:platform_console/domain/entities/handoff_recipient.dart';
import 'package:platform_console/domain/entities/issue_comment.dart';
import 'package:platform_console/domain/entities/merge_request_info.dart';
import 'package:platform_console/domain/entities/slash_command.dart';
import 'package:platform_console/domain/repositories/platform_repository.dart';
import 'package:platform_console/domain/usecases/suggest_command_arguments.dart';
import 'package:platform_console/l10n/gen/app_localizations.dart';
import 'package:platform_console/presentation/bloc/sessions_bloc.dart';
import 'package:platform_console/presentation/screens/sessions_screen.dart';

class _FakePlatformRepository implements PlatformRepository {
  @override
  String? get rootPath => '/tmp/fake-platform';

  @override
  String get role => 'ios';

  @override
  String get roleKey => 'AVTOTO_ROLE';

  @override
  List<SlashCommand> slashCommands() => const [
        SlashCommand(
            id: 'opsx-apply',
            description: 'Implement tasks from a change',
            argumentHint: '[change]'),
        SlashCommand(
            id: 'opsx-sprint',
            description: 'Sprint level actions',
            argumentHint: '[sprint] [status|build|handover|finish]'),
      ];

  @override
  ({List<String> changeIds, List<String> groupIds}) argumentValues() => (
        changeIds: ['biometric-opt-in', 'pin-setup-flow'],
        groupIds: ['pin-biometric-auth'],
      );

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        groups: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        redmineProblem: RedmineProblem.none,
        refreshedAt: DateTime.now(),
      );

  @override
  Future<String> readDoc(String absolutePath) async => '';

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
  Future<List<String>> knownSpecs() async => const ['/tmp/fake-platform'];

  @override
  Future<EnvForm> envForm() async => EnvForm.empty;

  @override
  Future<void> saveEnv(Map<String, String> values) async {}
}

Widget _wrap(SessionsBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: BlocProvider.value(value: bloc, child: const SessionsScreen()),
      ),
    );

void main() {
  group('SuggestCommandArguments', () {
    const suggester = SuggestCommandArguments(
      changeIds: ['biometric-opt-in', 'pin-setup-flow'],
      groupIds: ['pin-biometric-auth'],
    );

    test('первый аргумент [change] — список change\'ей', () {
      const command = SlashCommand(
          id: 'opsx-apply', description: '', argumentHint: '[change]');
      final suggestions = suggester(command, const [], '');
      expect(suggestions.map((s) => s.value),
          containsAll(['biometric-opt-in', 'pin-setup-flow']));
    });

    test('фильтрация по префиксу', () {
      const command = SlashCommand(
          id: 'opsx-apply', description: '', argumentHint: '[change]');
      final suggestions = suggester(command, const [], 'pin');
      expect(suggestions.map((s) => s.value), ['pin-setup-flow']);
    });

    test('второй аргумент — литеральные варианты из hint', () {
      const command = SlashCommand(
          id: 'opsx-sprint',
          description: '',
          argumentHint: '[sprint] [status|build|handover|finish]');
      final suggestions =
          suggester(command, const ['pin-biometric-auth'], '');
      expect(suggestions.map((s) => s.value),
          ['status', 'build', 'handover', 'finish']);
    });

    test('аргументы закончились — подсказок нет', () {
      const command = SlashCommand(
          id: 'opsx-apply', description: '', argumentHint: '[change]');
      final suggestions = suggester(command, const ['biometric-opt-in'], '');
      expect(suggestions, isEmpty);
    });
  });

  group('Экран сессий', () {
    late SessionsBloc bloc;

    /// Приложение десктопное: минимальное окно ~1100×700 (бриф §9),
    /// тестовые 800×600 не отражают реальную раскладку.
    /// Bloc создаётся внутри теста: созданный в setUp, он живёт вне
    /// фейкового времени, и его события не доходят до перерисовки.
    Future<void> pumpScreen(WidgetTester tester) async {
      bloc = SessionsBloc(_FakePlatformRepository());
      addTearDown(bloc.close);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(bloc));
      await tester.pumpAndSettle();
    }

    testWidgets('команда без пробела не роняет экран и показывает аргументы',
        (tester) async {
      await pumpScreen(tester);

      // Ровно тот ввод, что вызывал RangeError: имя команды без пробела.
      await tester.enterText(find.byType(TextField), '/opsx-apply');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('biometric-opt-in'), findsOneWidget);
    });

    testWidgets('клик по подсказке аргумента дописывает значение',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), '/opsx-apply');
      await tester.pumpAndSettle();
      await tester.tap(find.text('biometric-opt-in'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '/opsx-apply biometric-opt-in ');
    });

    testWidgets('палитра открывается кнопкой и показывает источник',
        (tester) async {
      await pumpScreen(tester);

      // Палитра — состояние строки ввода, а не постоянный список:
      // до нажатия её нет.
      expect(find.text('КОМАНДЫ СПЕКИ'), findsNothing);
      await tester.tap(find.text('Все команды спеки'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('КОМАНДЫ СПЕКИ'), findsOneWidget);
      expect(find.text('/opsx-apply'), findsWidgets);
      expect(find.text('[change]'), findsOneWidget);
      expect(find.text('.claude'), findsWidgets);
    });

    testWidgets('набранное «/» отбирает команды и показывает счётчик',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), '/opsx-sp');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('фильтр /opsx-sp · 1 из 2'), findsOneWidget);
      expect(find.text('/opsx-sprint'), findsWidgets);
    });

    testWidgets('выбор команды подставляет её в ту же строку ввода',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Все команды спеки'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('/opsx-sprint').first);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '/opsx-sprint ');
      expect(find.text('КОМАНДЫ СПЕКИ'), findsNothing);
    });

    testWidgets('минимальное окно: развёрнутый терминал с палитрой влезает',
        (tester) async {
      await pumpScreen(tester);
      tester.view.physicalSize = AppDimens.minWindowSize;
      await tester.pumpAndSettle();

      bloc.add(SessionTerminalHeightChanged(360));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Все команды спеки'));
      await tester.pumpAndSettle();

      // Переполнение раскладки роняет кадр исключением — его и ловим.
      expect(tester.takeException(), isNull);
      expect(find.text('КОМАНДЫ СПЕКИ'), findsOneWidget);
    });

    testWidgets('быстрый запуск показывает команды ролей', (tester) async {
      await pumpScreen(tester);

      // Выделенная кнопка одна — роль «реализовать».
      expect(find.text('Реализовать'), findsOneWidget);
      expect(find.text('/opsx-apply'), findsOneWidget);
      // Вторая роль спеки — передача (её берёт /opsx-sprint) — живёт
      // в «Ещё», а не спорит за ширину строки заголовка.
      expect(find.text('Ещё'), findsOneWidget);
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      expect(find.text('Передача'), findsOneWidget);
      expect(find.text('/opsx-sprint'), findsOneWidget);
      // Ролей «новый change» и «новая группа» у этой спеки нет.
      expect(find.text('Новый change'), findsNothing);
    });
  });
}
