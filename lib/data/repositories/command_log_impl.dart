import 'dart:async';

import '../../domain/entities/command_run.dart';
import '../../domain/repositories/command_log.dart';

class CommandLogImpl implements CommandLog {
  final _controller = StreamController<CommandRun>.broadcast();
  CommandRun? _last;

  @override
  Stream<CommandRun> get runs => _controller.stream;

  @override
  CommandRun? get last => _last;

  @override
  CommandRun begin(String command) {
    final run = CommandRun(
      command: command,
      output: '',
      exitCode: null,
      duration: Duration.zero,
      startedAt: DateTime.now(),
    );
    _last = run;
    _controller.add(run);
    return run;
  }

  @override
  void complete(CommandRun run,
      {required String output, required int exitCode}) {
    final finished = run.finished(
      output: output,
      exitCode: exitCode,
      duration: DateTime.now().difference(run.startedAt),
    );
    _last = finished;
    _controller.add(finished);
  }
}
