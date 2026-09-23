import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/handoff_recipient.dart';
import '../../domain/repositories/command_log.dart';
import 'executable_locator.dart';

/// Получатели передачи — их подбирает существующий скрипт платформы
/// (роли Redmine × членство в канале Mattermost). Приложение не повторяет
/// эту логику, а запускает скрипт и показывает результат до отправки.
class HandoverRecipientsSource {
  final Directory platformRoot;

  /// Путь скрипта относительно корня спеки; null — спека его не держит.
  final String? scriptPath;

  final CommandLog? commandLog;

  HandoverRecipientsSource(this.platformRoot,
      {this.scriptPath, this.commandLog});

  Future<HandoffRecipients> forStack(String stack) async {
    final scriptPath = this.scriptPath;
    if (scriptPath == null ||
        !File(p.join(platformRoot.path, scriptPath)).existsSync()) {
      return const HandoffRecipients(error: 'script-missing');
    }
    // .app из Finder наследует урезанный PATH: ищем node по абсолютному пути.
    final node = ExecutableLocator.locate('node');
    if (node == null) {
      return const HandoffRecipients(
          error: 'node не найден: установите Node.js (brew install node)');
    }
    final command = 'node $scriptPath --stack $stack';
    final run = commandLog?.begin(command);
    try {
      final result = await Process.run(
        node,
        [scriptPath, '--stack', stack],
        workingDirectory: platformRoot.path,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 40));
      final output = '${result.stdout}${result.stderr}'.trim();
      if (run != null) {
        commandLog?.complete(run, output: output, exitCode: result.exitCode);
      }
      if (result.exitCode != 0) {
        return HandoffRecipients(error: output.split('\n').last);
      }
      return _parse(result.stdout as String);
    } catch (error) {
      if (run != null) {
        commandLog?.complete(run, output: '$error', exitCode: 1);
      }
      return HandoffRecipients(error: '$error');
    }
  }

  /// Разбор вывода скрипта:
  /// «Тестировщики:» → «- @username — Имя (Redmine 328)».
  HandoffRecipients _parse(String stdout) {
    final bySection = <String, List<HandoffRecipient>>{
      'Тестировщики': [],
      'Менеджеры': [],
      'Разработчики': [],
    };
    final linePattern =
        RegExp(r'^-\s*@(\S+)\s+—\s+(.+?)\s+\(Redmine\s+(\d+)\)\s*$');
    String? section;
    for (final line in const LineSplitter().convert(stdout)) {
      final header = bySection.keys
          .where((key) => line.trimRight() == '$key:')
          .firstOrNull;
      if (header != null) {
        section = header;
        continue;
      }
      final match = linePattern.firstMatch(line.trim());
      if (match != null && section != null) {
        bySection[section]!.add(HandoffRecipient(
          username: match.group(1)!,
          name: match.group(2)!,
          redmineId: int.parse(match.group(3)!),
        ));
      }
    }
    return HandoffRecipients(
      testers: bySection['Тестировщики']!,
      managers: bySection['Менеджеры']!,
      developers: bySection['Разработчики']!,
    );
  }
}
