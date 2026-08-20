import '../entities/slash_command.dart';

/// Подсказка значения аргумента команды.
class ArgumentSuggestion {
  final String value;
  final String hint; // человеческое пояснение, может быть пустым

  const ArgumentSuggestion(this.value, {this.hint = ''});
}

/// Что предложить для очередного аргумента команды.
/// Позиции и допустимые значения берутся из `argument-hint` команды:
/// `[change] [ios|android] [check|merged]` — тот же текст, что видит
/// человек в терминале.
class SuggestCommandArguments {
  final List<String> changeIds;
  final List<String> sprintIds;

  const SuggestCommandArguments(
      {required this.changeIds, required this.sprintIds});

  /// [typedArguments] — уже набранные аргументы после имени команды.
  List<ArgumentSuggestion> call(
    SlashCommand command,
    List<String> typedArguments,
    String currentPrefix,
  ) {
    final slots = _parseSlots(command.argumentHint);
    if (typedArguments.length >= slots.length) return const [];
    final slot = slots[typedArguments.length];
    final candidates = _valuesFor(slot);
    final prefix = currentPrefix.toLowerCase();
    return [
      for (final candidate in candidates)
        if (candidate.value.toLowerCase().contains(prefix)) candidate,
    ];
  }

  /// «[change] [ios|android]» → ['change', 'ios|android'].
  List<String> _parseSlots(String argumentHint) => RegExp(r'\[([^\]]+)\]')
      .allMatches(argumentHint)
      .map((match) => match.group(1)!.trim())
      .toList();

  List<ArgumentSuggestion> _valuesFor(String slot) {
    // Флаг вида «--stack android|ios» — предлагаем значения с флагом.
    final flagMatch = RegExp(r'^(--[a-z-]+)\s+(.+)$').firstMatch(slot);
    if (flagMatch != null) {
      return [
        for (final value in flagMatch.group(2)!.split('|'))
          ArgumentSuggestion('${flagMatch.group(1)} ${value.trim()}'),
      ];
    }
    if (slot == 'change') {
      return [for (final id in changeIds) ArgumentSuggestion(id)];
    }
    if (slot == 'sprint') {
      return [for (final id in sprintIds) ArgumentSuggestion(id)];
    }
    // Смешанный слот «change|описание» — подставляем change'и,
    // произвольный текст человек допишет сам.
    if (slot.split('|').contains('change')) {
      return [for (final id in changeIds) ArgumentSuggestion(id)];
    }
    if (slot.contains('|')) {
      return [
        for (final value in slot.split('|')) ArgumentSuggestion(value.trim()),
      ];
    }
    return const [];
  }
}
