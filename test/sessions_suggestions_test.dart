import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_console/domain/entities/console_snapshot.dart';
import 'package:platform_console/domain/entities/env_report.dart';
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
  ({List<String> changeIds, List<String> sprintIds}) argumentValues() => (
        changeIds: ['biometric-opt-in', 'pin-setup-flow'],
        sprintIds: ['pin-biometric-auth'],
      );

  @override
  Future<ConsoleSnapshot> load() async => ConsoleSnapshot(
        sprints: const [],
        changes: const [],
        divergences: const [],
        env: const EnvReport(keys: [], repos: [], systems: []),
        redmineProblem: RedmineProblem.none,
        refreshedAt: DateTime.now(),
      );

  @override
  Future<String> readDoc(String absolutePath) async => '';

  @override
  Future<String> configFilePath() async => '/tmp/fake-config/.env';

  @override
  Future<bool> setPlatformDir(String path) async => true;
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
      sprintIds: ['pin-biometric-auth'],
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

    setUp(() => bloc = SessionsBloc(_FakePlatformRepository()));
    tearDown(() => bloc.close());

    /// Приложение десктопное: минимальное окно ~1100×700 (бриф §9),
    /// тестовые 800×600 не отражают реальную раскладку.
    Future<void> pumpScreen(WidgetTester tester) async {
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

    testWidgets('палитра команд помещается без переполнения', (tester) async {
      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('/opsx-apply'), findsWidgets);
    });
  });
}
