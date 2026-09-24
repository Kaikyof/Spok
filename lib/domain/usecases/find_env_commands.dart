import '../entities/env_task.dart';
import '../entities/slash_command.dart';

/// Какой командой спеки лечится нехватка в каждом разделе «Окружения».
///
/// Кнопку «make init» зашивать нельзя: у avelacom это `make init`, у другой
/// спеки — `pnpm workspace:init`, у третьей вообще ничего. Поэтому команду
/// ищем среди распознанных по словам в её имени и строке запуска, а не
/// знаем наперёд. Ничего не нашли — кнопки нет: предлагать команду,
/// которой у спеки не существует, хуже, чем не предлагать ничего.
class FindEnvCommands {
  const FindEnvCommands();

  /// Слова, по которым команда относится к разделу, и их вес. Вес нужен,
  /// чтобы `workspace-init` выиграл у просто `init`, а `verify` не увёл
  /// к себе клонирование.
  static const _weights = {
    EnvTask.repos: {
      'workspace': 3,
      'clone': 2,
      'init': 2,
      'bootstrap': 2,
      'sync': 1,
    },
    // У ключей своих слов немного, и слова «init» среди них нет:
    // `workspace-init` готовит репозитории, а не ключи, и предлагать его
    // в разделе ключей значило бы врать.
    EnvTask.keys: {
      'env': 3,
      'dotenv': 3,
      'secret': 3,
      'keys': 2,
    },
    EnvTask.systems: {
      'verify': 3,
      'doctor': 3,
      'healthcheck': 3,
      'check': 2,
      'status': 1,
    },
  };

  Map<EnvTask, SlashCommand> call(List<SlashCommand> commands) => {
        for (final task in EnvTask.values) task: ?_bestFor(task, commands),
      };

  SlashCommand? _bestFor(EnvTask task, List<SlashCommand> commands) {
    SlashCommand? best;
    var bestScore = 0;
    for (final command in commands) {
      final score = _score(task, command);
      // Строго больше: при равенстве остаётся найденная раньше — порядок
      // задаёт discovery, а он ставит канон схемы выше зеркал.
      if (score > bestScore) {
        best = command;
        bestScore = score;
      }
    }
    return best;
  }

  int _score(EnvTask task, SlashCommand command) {
    final text = '${command.id} ${command.runLine}'.toLowerCase();
    var score = 0;
    _weights[task]!.forEach((word, weight) {
      if (text.contains(word)) score += weight;
    });
    if (score == 0) return 0;
    // Команды, которые запускаются сами (цель Makefile, скрипт пакета),
    // предпочтительнее агентных: человеку нужно «выполнить», а не
    // «попросить агента выполнить».
    if (command.source == CommandSource.makeTarget ||
        command.source == CommandSource.packageScript) {
      score += 2;
    }
    // Сигнатура с аргументами говорит, что команда про другое: работа
    // с окружением аргументов не требует.
    if (command.slots.isNotEmpty) score -= 1;
    return score;
  }
}
