import 'dart:io';

import '../../domain/repositories/command_log.dart';
import 'executable_locator.dart';

/// Открытие файла спеки в редакторе.
///
/// Приложение не знает, какой IDE у человека, и не спрашивает: берёт первый
/// установленный из списка привычных, а если не нашло ни одного — отдаёт файл
/// системе (`open` на macOS, `xdg-open` на Linux). Запуск идёт через
/// абсолютный путь: у .app из DMG урезанный PATH.
class IdeLauncher {
  final CommandLog? commandLog;

  const IdeLauncher({this.commandLog});

  /// Редакторы в порядке предпочтения: имя утилиты и её аргументы к пути.
  static const _editors = [
    ('cursor', ['--goto']),
    ('code', ['--goto']),
    ('windsurf', ['--goto']),
    ('idea', []),
    ('subl', []),
    ('zed', []),
  ];

  /// Открывает [path]; false — не нашлось ни редактора, ни системной команды.
  Future<bool> open(String path) async {
    for (final (name, options) in _editors) {
      final executable = ExecutableLocator.locate(name);
      if (executable == null) continue;
      if (await _run(executable, [...options, path], label: name)) return true;
    }
    final fallback = Platform.isMacOS ? 'open' : 'xdg-open';
    final executable = ExecutableLocator.locate(fallback);
    if (executable == null) return false;
    return _run(executable, [path], label: fallback);
  }

  Future<bool> _run(String executable, List<String> arguments,
      {required String label}) async {
    final run = commandLog?.begin('$label ${arguments.join(' ')}');
    try {
      final result = await Process.run(executable, arguments)
          .timeout(const Duration(seconds: 10));
      if (run != null) {
        commandLog?.complete(run,
            output: '${result.stdout}${result.stderr}'.trim(),
            exitCode: result.exitCode);
      }
      return result.exitCode == 0;
    } catch (error) {
      if (run != null) commandLog?.complete(run, output: '$error', exitCode: 1);
      return false;
    }
  }
}
