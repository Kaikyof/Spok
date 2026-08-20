/// Команда платформы из `.claude/commands/<id>.md`.
/// Описание берётся из frontmatter файла — источник тот же, что у терминала.
class SlashCommand {
  final String id; // «opsx-sprint»
  final String description;
  final String argumentHint; // «[change]», может быть пустым

  const SlashCommand({
    required this.id,
    required this.description,
    this.argumentHint = '',
  });

  /// Как команда набирается в сессии.
  String get invocation => '/$id';
}
