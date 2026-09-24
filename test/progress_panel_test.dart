import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spok/domain/entities/operation_progress.dart';
import 'package:spok/l10n/gen/app_localizations.dart';
import 'package:spok/presentation/ui_kit/progress_panel.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(body: Center(child: child)),
    );

/// Правила борда 19 для длинной операции — их и проверяем: отмена рядом
/// с полосой, проценты только когда они известны, ошибка внутри блока.
void main() {
  testWidgets('отмена видна, пока операция идёт', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(_wrap(ProgressPanel(
      title: 'Клонируем репозиторий',
      progress: const OperationProgress.running(fraction: 0.42),
      onCancel: () => cancelled = true,
    )));

    expect(find.text('Клонируем репозиторий'), findsOneWidget);
    expect(find.text('42 %'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    expect(cancelled, isTrue);
  });

  testWidgets('объём неизвестен — полоса неопределённая, процентов нет',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProgressPanel(
      title: 'Читаем спеку',
      progress: OperationProgress.running(),
    )));

    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, isNull);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('ошибка показывает текст инструмента и «Повторить»',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(ProgressPanel(
      title: 'Не удалось склонировать',
      progress: const OperationProgress.failed(
          'Permission denied (publickey).'),
      onRetry: () => retried = true,
    )));

    expect(find.text('Permission denied (publickey).'), findsOneWidget);
    // Полосы при ошибке нет: двигать её некуда.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // Отмены тоже нет — отменять уже нечего.
    expect(find.text('Отменить'), findsNothing);

    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });

  testWidgets('операция не начата — блок не занимает места', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressPanel(
        title: 'Клонируем', progress: OperationProgress.idle)));

    expect(find.text('Клонируем'), findsNothing);
  });

  testWidgets('объём словами показывается под полосой', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressPanel(
      title: 'Клонируем репозиторий',
      progress: OperationProgress.running(fraction: 0.5),
      measure: '12 МБ из 40 МБ',
    )));

    expect(find.text('12 МБ из 40 МБ'), findsOneWidget);
  });
}
