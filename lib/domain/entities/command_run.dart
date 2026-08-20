/// Выполненная приложением команда — то, что показывает панель запуска.
/// Вывод не приукрашивается: человек должен повторить её руками (бриф §5.5).
class CommandRun {
  final String command; // точная строка, которую можно скопировать
  final String output;
  final int? exitCode; // null — ещё выполняется
  final Duration duration;
  final DateTime startedAt;

  const CommandRun({
    required this.command,
    required this.output,
    required this.exitCode,
    required this.duration,
    required this.startedAt,
  });

  bool get isRunning => exitCode == null;

  bool get succeeded => exitCode == 0;

  CommandRun finished({
    required String output,
    required int exitCode,
    required Duration duration,
  }) =>
      CommandRun(
        command: command,
        output: output,
        exitCode: exitCode,
        duration: duration,
        startedAt: startedAt,
      );
}
