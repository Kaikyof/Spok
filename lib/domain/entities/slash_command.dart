/// Откуда взялась команда спеки. Источник виден в палитре: канон схемы и
/// копия в `.claude` — разные вещи, и человек должен различать их до запуска.
enum CommandSource {
  schema, // openspec/schemas/<schema>/commands — канон
  claude, // .claude/commands
  skill, // .claude/skills
  mirror, // .agents, .codex, .cursor, .opencode, .github/prompts и другие
  packageScript, // scripts в package.json
  makeTarget, // цели Makefile
}

/// Куда команда попадает в интерфейсе. Выводится из сигнатуры автоматически:
/// настройка для этого не нужна (сводный документ, 4.6).
enum CommandScope {
  change, // меню действий карточки change'а
  group, // экран группы
  general, // общее меню команд
  paletteOnly, // сигнатура не распознана — только палитра
}

/// Команда платформы из `.claude/commands/<id>.md`.
/// Описание берётся из frontmatter файла — источник тот же, что у терминала.
class SlashCommand {
  final String id; // «opsx-sprint»
  final String description;
  final String argumentHint; // «[change]», может быть пустым

  /// Откуда команда: первый — главный источник, остальные — склеенные с
  /// ней дубли («команда · скилл» у upstream).
  final List<CommandSource> sources;

  /// Как команда запускается вне агента (скрипт или цель); пусто у markdown.
  final String runLine;

  const SlashCommand({
    required this.id,
    required this.description,
    this.argumentHint = '',
    this.sources = const [CommandSource.claude],
    this.runLine = '',
  });

  CommandSource get source => sources.first;

  /// Как команда набирается в сессии. Скрипты вызываются как есть.
  String get invocation => runLine.isNotEmpty ? runLine : '/$id';

  /// Слоты сигнатуры: «[change] [ios|android]» → ['change', 'ios|android'].
  List<String> get slots =>
      RegExp(r'\[([^\]]+)\]')
          .allMatches(argumentHint)
          .map((match) => match.group(1)!.trim())
          .toList();

  /// Подходит ли команда на роль по имени.
  bool fits(CommandRole role) {
    // Ищем по имени команды: слово из сигнатуры («--doc» у propose)
    // означает аргумент, а не роль. Исключение — передача: спеки называют
    // её и в подсказке аргументов.
    final haystack = (role == CommandRole.handover ? '$id $argumentHint' : id)
        .toLowerCase();
    return _roleKeywords[role]!.any(haystack.contains);
  }

  /// Первая подходящая роль; null — выделенной кнопки у команды нет.
  CommandRole? get role => CommandRole.values.where(fits).firstOrNull;

  /// Применимость — из сигнатуры, а не из настройки.
  CommandScope get scope {
    if (argumentHint.isEmpty) {
      // У скриптов сигнатуры не бывает — им место в общем меню.
      if (source == CommandSource.packageScript ||
          source == CommandSource.makeTarget) {
        return CommandScope.general;
      }
      // Команды upstream сигнатуру не пишут, но их роль известна: propose
      // создаёт change, apply и archive работают с готовым.
      return switch (role) {
        CommandRole.newChange => CommandScope.general,
        CommandRole.apply || CommandRole.archive => CommandScope.change,
        _ => CommandScope.paletteOnly,
      };
    }
    final names = slots.expand((slot) => slot.split('|')).toList();
    if (names.contains('change')) return CommandScope.change;
    if (names.any((name) => const ['sprint', 'group', 'doc'].contains(name))) {
      return CommandScope.group;
    }
    return CommandScope.general;
  }
}

/// Роль команды — у кого выделенная кнопка. Ролей намеренно мало: всё
/// остальное живёт в меню действий и палитре.
enum CommandRole { apply, newChange, newGroup, handover, archive }

const _roleKeywords = {
  CommandRole.apply: ['apply', 'implement', 'realize'],
  CommandRole.newChange: ['propose', 'new-change', 'change-new'],
  CommandRole.newGroup: ['doc', 'sprint-new', 'new-sprint'],
  CommandRole.handover: ['handover', 'handoff'],
  // sync и verify роли не получают: им место в меню «Ещё».
  CommandRole.archive: ['archive'],
};

/// Подбирает команду на каждую роль по имени и сигнатуре. Кандидата нет —
/// выделенной кнопки нет: выдумывать её за спеку нельзя.
Map<CommandRole, SlashCommand> resolveCommandRoles(
  List<SlashCommand> commands,
) {
  // Скилл уступает команде: у avtoto `openspec-redmine-archive` — шаг
  // внутри `/opsx-archive`, а не замена ему.
  final ordered = [
    ...commands.where((command) => command.source != CommandSource.skill),
    ...commands.where((command) => command.source == CommandSource.skill),
  ];
  return {
    for (final role in CommandRole.values)
      role: ?ordered.where((command) => command.fits(role)).firstOrNull,
  };
}
