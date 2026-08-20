import '../entities/command_run.dart';

/// Журнал команд, которые приложение выполняет за человека.
/// Панель запуска подписывается на него и показывает последнюю.
abstract class CommandLog {
  Stream<CommandRun> get runs;

  CommandRun? get last;

  /// Отмечает начало команды; возвращает её для последующего завершения.
  CommandRun begin(String command);

  void complete(CommandRun run,
      {required String output, required int exitCode});
}
